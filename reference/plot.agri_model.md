# Plot a fitted model

Plot a fitted model

## Usage

``` r
# S3 method for class 'agri_model'
plot(
  x,
  type = c("observed", "residuals", "importance"),
  top = 12,
  n_perm = 3,
  ...
)
```

## Arguments

- x:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md).

- type:

  `"observed"` plots out-of-fold predictions against the truth with a
  one to one line, which is the honest version of the usual
  fitted-versus-observed figure; `"residuals"` plots residuals against
  the prediction, to expose bias that a single skill number hides;
  `"importance"` draws out-of-fold permutation importance.

- top:

  Number of features for `"importance"`.

- n_perm:

  Shuffles per feature for `"importance"`.

- ...:

  Passed to `plot`.

## Value

`x`, invisibly. Called for the plot.

## See also

[`plot_map()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_map.md),
[`plot_effect()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_effect.md),
[`plot_uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_uncertainty.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
m <- train_model(p, "yield", algorithm = "lm", k = 3)
plot(m)

plot(m, type = "residuals")
```
