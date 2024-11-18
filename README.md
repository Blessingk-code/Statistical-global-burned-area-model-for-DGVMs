This repository contains files supporting our paper on building a global statistical burned area model for seamless integration into Dynamic Global Vegetation Models (DGVMs).  

## Introduction  

Our paper, *A Statistical Global Burned Area Model for Seamless Integration into Dynamic Global Vegetation Models*, will be submitted to *Biogeosciences*.  

**Authors**:  
- Blessing Kavhu  
- Matthew Forrest  
- Thomas Hickler  

## Workflow and Code Components  

### 1. Download the Data  
Download the large data table from the Zenodo repository and place it in your working directory:
`https://doi.org/10.5281/zenodo.14110150`

### 2. Plot the Correlation Matrix  
Run the following script to generate the correlation matrix plot:  

`Model_fitting_&_plots/Correlation_matrix_plot_v1.R`

### 3. Fit the Models  
Run this script to fit various models and evaluate their performance based on deviance explained and normalized mean error:  

`Model_fitting_&_plots/Sensitivity_models_v1.R`

### 4. Generate Final Model and Plots  
Fit the final model and generate associated plots, including the spatial distribution map and partial residual plots, by running:  

`Model_fitting_&_plots/Final_model_&_plot_v1.R`

### 5. Plot Interannual Variability  
To visualize interannual variability, run:  

`Model_fitting_&_plots/Interannual_variability_plot_v1.R`

**Options for handling HDI:**  
- Exclude HDI  
- Keep HDI constant based on initial year values  
- Use HDI values for matching periods  

### 6. Plot Seasonal Variability  
Run the following script to plot seasonal variability:  

`Model_fitting_&_plots/Seasonal_variability_plot_v1.R`

### 7. Test for Trends in Burned Area Extent  
Analyze trends in burned area extent across different GFED regions by running:  

`Model_fitting_&_plots/Mankendall_trend_test_v1.R`

The required dataset is located at:  

`Datasets/GFED_trends.csv`

### 8. Plot Spatial Variation in Trends and R-Squared Values  
Visualize the following using the GeoJSON file provided:  
- Variation in trends of interannual variability by GFED region  
- Spatial distribution of R-squared values for annual and seasonal cycles  

The file to use is:  

`Datasets/GFED_regions_&_results.geojson`

These plots can be generated in any GIS software. Relevant fields for each parameter are included in the dataset.  
---


## Citation  
If you use this repository, please cite:  

*Authors*:  
- Blessing Kavhu  
- Matthew Forrest  
- Thomas Hickler  

*Title*: *A Statistical Global Burned Area Model for Seamless Integration into Dynamic Global Vegetation Models*  
*Journal*: *Biogeosciences*  
---

## Contact  
For any questions or issues, please contact: [kavhublessing@gmail.com]

