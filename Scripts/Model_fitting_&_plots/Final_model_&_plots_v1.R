# Load required libraries
library(terra)
library(data.table)
library(sf)
library(ncdf4)
library(ggplot2)
library(viridis)
library(cowplot) 
library(tictoc)
library(visreg)
library(viridis)
library(tidyterra)
library(rnaturalearthdata)
library(rnaturalearth)

# Load the data
annual_dt <- readRDS("/Master_dt_GF4DGVMs_V1.0.RDS")


head(annual_dt)


# Remove NAs and outliers
annual_dt <- na.omit(annual_dt)
annual_dt <- annual_dt[burnt <= 1] 

# Log transformation of FWI
annual_dt$FWI <- log(annual_dt$FWI)

# Split data into training and validation sets
annual_dtt <- subset(annual_dt, Year %in% 2002:2010)
annual_dtv <- subset(annual_dt, Year %in% 2011:2018)

# Model fitting
model <- glm(
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + NTC  + PPN + NDD + NTC + TPI,
  data = annual_dtt,
  family = quasibinomial
)

# Model summary
summary(model)

# Calculate Variance Inflation Factor (VIF)
vif_result <- car::vif(model)
print(vif_result)

# Model accuracy
summary_result <- summary(model)
dev_explained <- 1 - (summary_result$deviance / summary_result$null.deviance)
print(paste("Deviance Explained:", round(dev_explained * 100, 2), "%"))

# Predictions
annual_dtv$predicted_burnt <- predict(model, newdata = annual_dtv, type = "response")

# Summarize by grid cell
annual_dt_summed <- annual_dtv[, lapply(.SD, sum), .SDcols = c("burnt", "predicted_burnt"), by = .(X, Y)]
annual_dt_summed[, `:=`(burnt = burnt / 10, predicted_burnt = predicted_burnt / 10)]

# Create rasters
predicted_raster <- rast(annual_dt_summed)

##Assign projection to predicted raster
terra::crs(predicted_raster) <- "EPSG:4326"

#############plotting #####
###################################################################################
observed <- predicted_raster[[1]]
predictions <- predicted_raster[[2]]
##plot(predictions)
from_vec <- c(0,0.002, 0.005, 0.01, 0.02, 0.03, 0.05, 0.10, 0.2, 0.50,1)
to_vec <- c(0.002, 0.005, 0.01, 0.02,0.03, 0.05, 0.10, 0.2, 0.50, 1)

labels_vec <- paste(from_vec , to_vec, sep = "-")
###################################################
# Create discrete rasters for both years
discrete_observed <- terra::classify(observed, from_vec, right = FALSE, include.lowest = TRUE)
discrete_predictions <- terra::classify(predictions, from_vec, right = FALSE, include.lowest = TRUE)



# Load country boundaries for context
world <- ne_countries(scale = "medium", returnclass = "sf")

# Plot observed with global map projection
plot_observed <- ggplot() +
  geom_spatraster(data =discrete_observed) +
  geom_sf(data = world, fill = NA, color = "gray50", size = 0.02) + # Add world outline
  scale_fill_viridis(option = "turbo", name = " Burnt area fraction", 
                     discrete = TRUE, labels = labels_vec, direction = 1, drop = TRUE) +
  labs(title = "Observed burnt area (GFED5)") +
  coord_sf(crs = "ESRI:54030") +  # Apply Robinson projection
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        legend.key.size = unit(0.3, "cm"),    # Adjust size of legend keys
        legend.text = element_text(size = 8),  # Adjust size of legend text
        legend.title = element_text(size = 10),
        plot.margin = margin(2))  # Title centered, larger and bolder


# Plot predicted with similar settings
plot_predictions <- ggplot() +
  geom_spatraster(data = discrete_predictions) +
  geom_sf(data = world, fill = NA, color = "gray50", size = 0.02) + # Add world outline
  scale_fill_viridis(option = "turbo", name = "Burnt area fraction", 
                     discrete = TRUE, labels = labels_vec, direction = 1, drop = TRUE) +
  labs(title = "Predicted burnt area") +
  coord_sf(crs = "ESRI:54030") +  # Apply Robinson projection
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        legend.key.size = unit(0.3, "cm"),    # Adjust size of legend keys
        legend.text = element_text(size = 8),  # Adjust size of legend text
        legend.title = element_text(size = 10),
        plot.margin = margin(2))  # Title centered, larger and bolder


# Arrange the plots side by side
##map_grid <- plot_grid(plot_observed, plot_predictions, nrow = 2)
map_grid <- plot_grid(plot_observed, plot_predictions, nrow = 2, rel_heights = c(2, 2))

# Display the result
print(map_grid)

# Save to PDF
ggsave("map_grid_plot15.pdf", plot = map_grid, device = "pdf", width = 8, height = 7)


###Plotting partial residual plots

# Set up the plotting layout: 3 rows by 4 columns
# 'mfrow' determines the number of rows and columns for the plot grid
# 'mgp' adjusts the position of axis labels and title, while 'mar' sets margins
# 'tcl' adjusts the length of axis ticks
par(mfrow = c(3, 4), mgp = c(1.3, 0.3, 0), mar = c(3.5, 4, 0.3, 0.5), tcl = 0.3)

# Begin saving the plots as a PDF file
# The 'pdf' function will capture all the plots and save them in a file
pdf("model_visualizations.pdf", width = 12, height = 9)

# Function to create individual plots using visreg() to visualize model predictions
# 'model' is the regression model
# 'var_name' is the variable to be visualized in the plot
# 'x_label' and 'y_label' are the labels for the x and y axes
# 'title' is the title of the plot
# 'line_col' is the color of the regression line (default is green)
plot_visreg <- function(model, var_name, x_label, y_label, title, line_col = "green") {
  
  # Create the visualization for the specified variable using visreg
  # visreg() plots the model's predicted values against the specified variable
  visreg(model, var_name, 
         line = list(col = line_col),  # Set line color
         points = list(cex = 0.00001, pch = 0.00001),  # Set minimal point size to reduce clutter
         xlab = x_label,  # X-axis label
         ylab = y_label,  # Y-axis label
         cex = 1.7)  # Scale the size of the plot
  
  # Add a custom title above the plot using mtext
  mtext(title, side = 3, line = -2, cex = 1.2)  # Side 3 indicates title is above the plot, line = -2 gives appropriate spacing
}

# First Plot - GPP Index
# Visualizes the relationship between GPP Index and the response variable (f(BA))
plot_visreg(model, "GPPI", "GPP Index", "f(BA)", "GPP Index")

# Second Plot - Fire Weather Index
# Visualizes the relationship between FWI and the response variable (f(BA))
plot_visreg(model, "FWI", "Log FWI", "f(BA)", "Fire Weather Index")

# Third Plot - Percentage Non Tree Cover (NTC)
# Visualizes the relationship between NTC and the response variable (f(BA))
plot_visreg(model, "NTC", "Percentage Non tree Cover", "f(BA)", "Percentage Non tree Cover")

# Fourth Plot - Human Development Index (HDI)
# Visualizes the relationship between HDI and the response variable (f(BA))
plot_visreg(model, "HDI", "Human Development Index", "f(BA)", "Human Development Index")

# Fifth Plot - Percentage Tree Cover (PTC)
# Visualizes the relationship between PTC and the response variable (f(BA))
plot_visreg(model, "PTC", "Percentage Tree Cover", "f(BA)", "Percentage Tree Cover")

# Sixth Plot - Number of Dry Days (dry)
# Visualizes the relationship between dry days and the response variable (f(BA))
plot_visreg(model, "NDD", "Number of dry days", "f(BA)", "Number of dry days")

# Seventh Plot - Population Density (PPN)
# Visualizes the relationship between Population Density and the response variable (f(BA))
plot_visreg(model, "PPN", "Population density", "f(BA)", "Population Density")

# Eighth Plot - Topographic Position Index (TPI)
# Visualizes the relationship between TPI and the response variable (f(BA))
plot_visreg(model, "TPI", "Topographic position Index", "f(BA)", "Topographic Position Index")

# Close the PDF device to save the plots
dev.off()