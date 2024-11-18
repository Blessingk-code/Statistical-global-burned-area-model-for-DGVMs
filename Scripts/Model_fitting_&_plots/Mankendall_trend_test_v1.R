# Load necessary libraries
library(Kendall)
library(ggplot2)
library(trend)
library(openxlsx)

# Load your data
data <- read.csv("/GFED_trends.csv")

# View initial rows
head(data)

# Remove rows with missing values
data <- na.omit(data)

# Perform Mann-Kendall tests for each GFED column
mk_results <- lapply(data[, grep("GFED", names(data))], MannKendall)

# Print each result
lapply(mk_results, print)

# Extract results into a structured format
mk_summary <- do.call(rbind, lapply(names(mk_results), function(name) {
  result <- mk_results[[name]]
  data.frame(
    Variable = name,
    tau = result$tau,
    p_value = result$sl
  )
}))

# Save the results to an Excel spreadsheet
output_path <- "/MannKendall_Results.xlsx"
write.xlsx(mk_summary, output_path, rowNames = FALSE)

# Print a message indicating successful save
cat("Mann-Kendall results saved to:", output_path)