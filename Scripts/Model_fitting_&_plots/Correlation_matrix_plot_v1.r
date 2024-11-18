# Load required libraries
library(data.table)  # For handling data tables
library(reshape2)    # For reshaping data
library(ggplot2)     # For plotting

# Load the dataset
annual_dt <- readRDS("/Master_dt_GF4DGVMs_V1.0.RDS")
head(annual_dt)

# Set key columns for efficient data.table operations
setkey(annual_dt, X, Y, Date)

# Calculate moving averages and other derived variables for each X, Y combination
annual_dt[, FAPAR12 := shift(frollmean(FAPAR, n = 12, align = "right")), by = c("X", "Y")]
annual_dt[, FAPAR6 := shift(frollmean(FAPAR, n = 6, align = "right")), by = c("X", "Y")]
annual_dt[, max_GPP13 := frollapply(GPP, FUN = max, n = 13, align = "right"), by = c("X", "Y")]
annual_dt[, GPP_index := GPP / max_GPP13]

# Remove rows with missing values
annual_dt <- na.omit(annual_dt)

# Subset predictor variables for training
pred_var_training1 <- annual_dt[, 3:6]
pred_var_training2 <- annual_dt[, 8:21]
pred_var_training3 <- annual_dt[, 27:30]
pred_var_training <- cbind(pred_var_training1, pred_var_training2, pred_var_training3)

# Compute correlation matrix
cormat <- round(cor(pred_var_training), 2)

# Reshape correlation matrix for visualization
melted_cormat <- melt(cormat)

# Plot correlation matrix using a heatmap
ggplot(data = melted_cormat, aes(x = Var1, y = Var2, fill = value)) + 
  geom_tile() +
  theme_minimal() +
  scale_fill_gradient2(low = "blue", high = "red", midpoint = 0, name = "Correlation")

# Functions to extract upper and lower triangles of the correlation matrix
get_upper_tri <- function(cormat) {
  cormat[lower.tri(cormat)] <- NA
  return(cormat)
}

get_lower_tri <- function(cormat) {
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}

# Extract upper triangle of the correlation matrix for visualization
upper_tri <- get_upper_tri(cormat)
melted_cormat <- melt(upper_tri, na.rm = TRUE)

# Create heatmap with reordered correlation matrix
reorder_cormat <- function(cormat) {
  dd <- as.dist((1 - cormat) / 2)  # Convert correlation to distance
  hc <- hclust(dd)  # Hierarchical clustering
  cormat <- cormat[hc$order, hc$order]
}

# Reorder correlation matrix and plot heatmap
cormat <- reorder_cormat(cormat)
upper_tri <- get_upper_tri(cormat)
melted_cormat <- melt(upper_tri, na.rm = TRUE)

ggheatmap <- ggplot(melted_cormat, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", midpoint = 0, name = "Pearson\nCorrelation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 9, hjust = 1)) +
  coord_fixed()

# Print heatmap
print(ggheatmap)

# Add correlation coefficients to the heatmap
ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 3.5) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.6, 0.7),
    legend.direction = "horizontal") +
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5))