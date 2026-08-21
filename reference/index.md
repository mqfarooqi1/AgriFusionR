# Package index

## The project

The object everything else operates on: management units observed over
seasons, with a provenance ledger.

- [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  : Create an agricultural analysis project
- [`units_of()`](https://mqfarooqi1.github.io/AgriFusionR/reference/units_of.md)
  [`seasons_of()`](https://mqfarooqi1.github.io/AgriFusionR/reference/units_of.md)
  [`provenance()`](https://mqfarooqi1.github.io/AgriFusionR/reference/units_of.md)
  : Accessors for project components
- [`demo_agri_data()`](https://mqfarooqi1.github.io/AgriFusionR/reference/demo_agri_data.md)
  : A demonstration agricultural data set

## Covariates

Attaching climate, soil and remote-sensing layers through the source
registry, and reducing them to one row per unit and season.

- [`add_layer()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
  [`add_climate()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
  [`add_soil()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
  [`add_satellite()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
  : Attach a covariate layer to a project
- [`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)
  : Build the model design matrix
- [`growing_degree_days()`](https://mqfarooqi1.github.io/AgriFusionR/reference/growing_degree_days.md)
  : Growing degree days
- [`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md)
  : Indicative crop thermal parameters
- [`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)
  : Derive phenological windows from accumulated thermal time

## Checking

The faults that invalidate an analysis, including covariate windows that
reach past the harvest they predict.

- [`check_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/check_project.md)
  : Check a project for the faults that invalidate an analysis

## Modelling

Spatial resampling by default, with the optimism of random folds
reported alongside.

- [`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md)
  : Build a resampling scheme
- [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
  : Train and honestly validate a model
- [`predict(`*`<agri_model>`*`)`](https://mqfarooqi1.github.io/AgriFusionR/reference/predict.agri_model.md)
  : Predict from a fitted model
- [`stack_weights()`](https://mqfarooqi1.github.io/AgriFusionR/reference/stack_weights.md)
  : Stack weights from a fitted ensemble

## Interpretation

Importance, marginal effects, prediction intervals and model cards.

- [`explain()`](https://mqfarooqi1.github.io/AgriFusionR/reference/explain.md)
  : Explain a fitted model
- [`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md)
  : Prediction intervals by split conformal inference
- [`report()`](https://mqfarooqi1.github.io/AgriFusionR/reference/report.md)
  : Write a model card

## Plots

- [`plot(`*`<agri_project>`*`)`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot.agri_project.md)
  : Plot a project's management units
- [`plot(`*`<agri_resample>`*`)`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot.agri_resample.md)
  : Plot a resampling scheme
- [`plot(`*`<agri_model>`*`)`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot.agri_model.md)
  : Plot a fitted model
- [`plot_map()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_map.md)
  : Map predictions, residuals or uncertainty
- [`plot_effect()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_effect.md)
  : Plot a marginal effect
- [`plot_uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_uncertainty.md)
  : Plot prediction intervals and their coverage

## Extending

Adding a data provider or a learning algorithm without modifying the
package.

- [`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md)
  : Register a covariate source
- [`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md)
  : Register a learning algorithm
- [`list_sources()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md)
  [`list_learners()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md)
  : List registered sources and learners
