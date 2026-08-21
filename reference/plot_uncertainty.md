# Plot prediction intervals and their coverage

Observations are sorted by prediction and drawn with their conformal
interval, with the ones the interval missed picked out. A calibrated
interval should miss about `1 - level` of them, scattered rather than
concentrated at one end.

## Usage

``` r
plot_uncertainty(model, level = 0.9, ...)
```

## Arguments

- model:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md).

- level:

  Coverage level.

- ...:

  Passed to `plot`.

## Value

A data frame of predictions, bounds and whether each was covered,
invisibly.

## See also

[`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md),
[`predict.agri_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/predict.agri_model.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
m <- train_model(p, "yield", algorithm = "lm", k = 3)
plot_uncertainty(m)
```
