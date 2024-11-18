# Load required libraries
library(car)
library(terra)
library(data.table)
library(ggplot2)
library(raster)

# Load the data
annual_dt <- readRDS("/Master_dt_GF4DGVMs_V1.0.RDS")
FWI_2001 <- rast("/2001_monthly.nc")

###Add path to GFED regions
###GFED_region <- vect ('/GFED_regions.geojson')## Only use this plotting seasonal cycle per GFED region

# Data Cleaning
annual_dt <- na.omit(annual_dt)
annual_dt <- annual_dt[burnt <= 1]

# Log transformation of FWI
annual_dt$FWI <- log(annual_dt$FWI)

# Train-validation split (optional, based on your analysis needs)
# For seasonal analysis, we don't necessarily need to split by year
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

# Ensure Month column is numeric and uppercase
annual_dt$Month <- as.numeric(annual_dt$Month)
annual_dt$Month <- toupper(annual_dt$Month)  # Ensure uppercase if needed

# Prediction Loop for Seasonal Cycle (by Month)
months <- 1:12  # For months January to December
predicted_list <- lapply(months, function(mo) {
  nw_fit <- subset(annual_dt, Month == mo)  # Ensure matching month
  nw_fit[, predicted_burnt := predict(model, newdata = nw_fit, type = "response")]
  
  # Summing burnt and predicted burnt areas
  summed_data <- nw_fit[, lapply(.SD, sum), .SDcols = c("burnt", "predicted_burnt"), by = .(X, Y)]
  
  # Convert summed data to a raster object
  predicted_ras <- rast(summed_data)
  
  # Resample to match the resolution of FWI_2001 raster
  predicted_ras <- resample(predicted_ras, FWI_2001)  
  
  list(month = mo, predicted_ras = predicted_ras)
})

# Raster Area Calculation for Seasonal Cycle
area_calculations <- lapply(predicted_list, function(item) {
  month <- item$month
  pred <- item$predicted_ras[[2]] * cellSize(item$predicted_ras[[2]], unit = "km")
  obs <- item$predicted_ras[[1]] * cellSize(item$predicted_ras[[1]], unit = "km")
  
  # Store area calculations in a data.table
  data.table(Month = month, 
             pred_area = global(pred, fun = "sum", na.rm = TRUE),
             obs_area = global(obs, fun = "sum", na.rm = TRUE))
})

# Combine the area calculations into one data table
area_data <- rbindlist(area_calculations)

# Create the data frame containing both observed and predicted areas from the correct columns
area_data <- data.frame(
  Month = area_data$Month,              # Use the Month column from `area_data`
  obs_area = area_data$obs_area.sum,    # Use the `obs_area.sum` column
  pred_area = area_data$pred_area.sum   # Use the `pred_area.sum` column
)

# Now, plotting the Seasonal Cycle
ggplot(area_data, aes(x = factor(Month), group = 1)) +  # Add grouping by `Month`
  geom_line(aes(y = obs_area, color = "Observed"), linewidth = 1) +
  geom_line(aes(y = pred_area, color = "Predicted"), linewidth = 1, linetype = "dashed") +
  labs(
    title = "Observed vs Predicted Burnt Area (Seasonal Cycle)",
    y = "Burnt Area (sq.km)",
    x = "Month",
    color = "Legend"
  ) +
  scale_x_discrete(labels = month.name) +  # Converts numeric month to month name
  theme_minimal() +
  scale_color_manual(values = c("Observed" = "blue", "Predicted" = "red"))