# Statistical-global-burned-area-model-for-DGVMs
This repository contains files for our paper on building a global statistical burned area model for seamless integration into DGVMS 

# Introduction
Paper will be submitted to Biogeosciences:

A statistical global burned area model for seamless integration into Dynamic Global Vegetation Models
Blessing Kavhu, Matthew Forrest, and Thomas Hickler 

# Workflow and code components

1. Download the large data table from the Zenodo repository and put it into ypur working directory.
2. Plot the correlation matrix by running `Model_fitting_&_plots/Correlation_matrix_plot_v1.R`
3. Fit all the models by running `Model_fitting_&_plots/Sensitivity_models_v1.R`.  This should fit the different models and show their perfomance according to deviance explained and normalised mean error.
4. For the final model and all associated plots run `Model_fitting_&_plots/Final_model_&_plot_v1.R`. The plots includes the spatial distribution map and the partial residual plots.
5. Plot interannual variability by running `Model_fitting_&_plots/Interannual_variability_plot_v1.R`. There is an option to plot interannual variability based on different treatments of HDI (1. HDI excluded, 2. HDI held constant based on the values of the initial year of analysis, 3. HDI values for the matching periods)
6. Plot seasonal variability by running `Model_fitting_&_plots/Seasonal_variability_plot_v1.R`.
7. Test for trends in burnt area extent across different GFED regions by running `Model_fitting_&_plots/Mankendall_trend_test_v1.R`. Data for burnt area extent is provided in `Datasets/GFED_trends.csv`
8. Plot a map for variation in trend of interannual variability per GFED region, spatial distribution of R-square of annual cycles and spatial distribution of R-square of seasonal cycles using `Datasets/GFED_regions_&_results.geojson`. This can be plotted in any GIS software and the fields representing each parameter are provided. 

