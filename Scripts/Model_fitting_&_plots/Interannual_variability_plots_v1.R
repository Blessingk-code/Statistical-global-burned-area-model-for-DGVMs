# Load required libraries
library(car)
library(terra)
library(data.table)
library(ggplot2)
library(raster)

# Load the data
annual_dt <- readRDS("/Master_dt_GF4DGVMs_V1.0.RDS")
FWI_2001 <- rast("/2001_monthly.nc")

### Holding HDI constant at the first year's value
##first_year_hdi <- annual_dt[Year == "2002", .(HDI_first_year = HDI[1]), by = .(X, Y)]
##annual_dt <- merge(annual_dt, first_year_hdi, by = c("X", "Y"))
##annual_dt[, HDI := HDI_first_year]
##annual_dt[, HDI_first_year := NULL]

# Data Cleaning
annual_dt <- na.omit(annual_dt)
annual_dt <- annual_dt[burnt <= 1]

# Log transformation of FWI
annual_dt$FWI <- log(annual_dt$FWI)

# Train-validation split
annual_dtt <- subset(annual_dt, Year %in% 2002:2010)
annual_dtv <- subset(annual_dt, Year %in% 2011:2018)

# Fit the GLM model
model <- glm(
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + NTC + PPN + NDD + TPI,
  data = annual_dtt,
  family = quasibinomial
)

# Model Summary
summary(model)
print(car::vif(model))
dev_explained <- 1 - (summary(model)$deviance / summary(model)$null.deviance)
print(dev_explained)

# Prediction Loop & Summarization
years <- 2002:2018
predicted_list <- lapply(years, function(yr) {
  nw_fit <- subset(annual_dt, Year == yr)
  nw_fit[, predicted_burnt := predict(model, newdata = nw_fit, type = "response")]
  summed_data <- nw_fit[, lapply(.SD, sum), .SDcols = c("burnt", "predicted_burnt"), by = .(X, Y)]
  predicted_ras <- rast(summed_data)
  predicted_ras <- resample(predicted_ras, FWI_2001)  # Align resolution
  list(year = yr, predicted_ras = predicted_ras)
})

# Raster Area Calculation
area_calculations <- lapply(predicted_list, function(item) {
  year <- item$year
  pred <- item$predicted_ras[[2]] * cellSize(item$predicted_ras[[2]], unit = "km")
  obs <- item$predicted_ras[[1]] * cellSize(item$predicted_ras[[1]], unit = "km")
  data.table(Year = year, pred_area = global(pred, fun = "sum", na.rm = TRUE),
             obs_area = global(obs, fun = "sum", na.rm = TRUE))
})

area_data <- rbindlist(area_calculations)

# Create the data frame containing both observed and predicted areas from the correct columns
area_data <- data.frame(
  Year = area_data$Year,              # Use the Year column from `area_data`
  obs_area = area_data$obs_area.sum,  # Use the `obs_area.sum` column
  pred_area = area_data$pred_area.sum # Use the `pred_area.sum` column
)

# Now, plotting the data
library(ggplot2)
ggplot(area_data, aes(x = Year)) +
  geom_line(aes(y = obs_area, color = "Observed"), linewidth = 1) +
  geom_line(aes(y = pred_area, color = "Predicted"), linewidth = 1, linetype = "dashed") +
  labs(
    title = "Observed vs Predicted Burnt Area (2002-2018)",
    y = "Burnt Area (sq.km)",
    x = "Year",
    color = "Legend"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Observed" = "blue", "Predicted" = "red"))