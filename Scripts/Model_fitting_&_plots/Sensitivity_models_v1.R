# Load necessary libraries
library(terra)
library(data.table)
library(sf)
library(mgcv)
library(car) # For VIF calculation

# Load the data
annual_dt <- readRDS("/Master_dt_GF4DGVMs_V1.0.RDS")

# Remove NAs and outliers
annual_dt <- na.omit(annual_dt)
annual_dt <- annual_dt[burnt <= 1] 

# Log transformation of FWI
annual_dt$FWI <- log(annual_dt$FWI)

# Split data into training and validation sets
annual_dtt <- subset(annual_dt, Year %in% 2002:2010)
annual_dtv <- subset(annual_dt, Year %in% 2011:2018)

# Model formulas
model_formulas <- list(
  burnt ~ FWI + GPP + HDI + PTC + RD,
  burnt ~ FWI + GPP + HDI + PTC + RD + PGC,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR + PCC,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR + PCC + PPS,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR + PCC + PRC,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR + PCC + PGC,
  burnt ~ FWI + GPP + HDI + PTC + RD + NTC + FAPAR + PCC + FAPAR12 + PGC,
  burnt ~ FWI + GPP12 + HDI + poly(PTC, 2) + NTC + FAPAR + PCC + FAPAR12 + PGC + PPN,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + RD + NTC + FAPAR12 + PGC + PS,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + RD + NTC + FAPAR12 + PS,
  burnt ~ FWI + GPPI + HDI * PCC + PGC + RD + poly(PTC, 2) + NTC + PS,
  burnt ~ FWI + GPPI + HDI * PGC + RD + poly(PTC, 2) + NTC + PS,
  burnt ~ FWI + GPPI + HDI * PRC + RD + poly(PTC, 2) + NTC + PS,
  burnt ~ FWI + GPPI * NTC + HDI + RD + poly(PTC, 2) + PS,
  burnt ~ FWI + GPPI + HDI + RD + poly(PTC, 2) + NTC + PS + NDD,
  burnt ~ FWI + GPPI + HDI + RD + poly(PTC, 2) + NTC * PS + NDD + TPI,
  burnt ~ FWI + GPPI + HDI + RD + poly(PTC, 2) + NTC * PS + NDD + PGC + FAPAR12,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + NTC * PS + NDD + FAPAR12,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + RD + NTC * PS + NDD + TPI + PPN,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + NTC * PS + NDD + TPI + PPN,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + RD + NTC * PS + NDD + TPI + PPN,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + RD + NTC * PS + NDD + TPI + PPN + AAP,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) + NTC + PPN + NDD + TPI,
  burnt ~ FWI + GPPI + HDI + poly(PTC, 2) * NDD + NTC + PPN + TPI
)

# Initialize results table
results <- data.table(Model = character(), Deviance_Explained = numeric(), NME = numeric())

# Iteratively fit each model
for (i in seq_along(model_formulas)) {
  # Fit model
  model <- glm(model_formulas[[i]], data = annual_dtt, family = quasibinomial)
  
  # Calculate Deviance Explained
  dev_explained <- 1 - (summary(model)$deviance / summary(model)$null.deviance)
  
  # Make predictions on the validation set
  annual_dtv$predicted_burnt <- predict(model, newdata = annual_dtv, type = "response")
  
  # Aggregate predictions
  annual_dt_summed <- annual_dtv[, lapply(.SD, sum), .SDcols = c("burnt", "predicted_burnt"), by = c("X", "Y")]
  
  # Calculate NME
  observed <- annual_dt_summed$burnt
  predictions <- annual_dt_summed$predicted_burnt
  nme <- sum(abs(observed - predictions) / pmax(observed, predictions)) / length(observed)
  
  # Append results
  results <- rbind(results, data.table(Model = paste("Model", i), Deviance_Explained = dev_explained, NME = nme))
  
  # Save intermediate results
  fwrite(results, "intermediate_results.csv")
  
  # Print progress
  print(paste("Model", i, "completed"))
}

# Print final results
print(results)

# Save final results
fwrite(results, "final_results.csv")