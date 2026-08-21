# Predict from a fitted model

Predict from a fitted model

## Usage

``` r
# S3 method for class 'agri_model'
predict(object, newdata = NULL, interval = FALSE, level = 0.9, ...)
```

## Arguments

- object:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md).

- newdata:

  Optional data frame of features. When omitted, predictions for the
  training rows are returned, alongside the out-of-fold predictions,
  which are the honest ones.

- interval:

  Attach conformal prediction intervals.

- level:

  Coverage level for the interval.

- ...:

  Ignored.

## Value

A data frame with the keys, `.pred`, and when `newdata` is omitted
`.pred_oof`; plus `.lower` and `.upper` when `interval = TRUE`.

## See also

[`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
p <- build_features(phenology_windows(add_climate(p)))
m <- train_model(p, "yield", algorithm = "lm", k = 3)
#> Warning: 64 features for 36 observations. Unregularised linear learners will be rank deficient here; prefer a tree-based or penalised learner, or pass fewer `stats` to build_features().
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
head(predict(m, interval = TRUE))
#>   unit_id season_id .pred  .pred_oof    .lower   .upper
#> 1    F001      2018 7.976 -12.645130 -1064.044 1079.996
#> 2    F001      2019 7.948  17.146673 -1064.072 1079.968
#> 3    F001      2020 7.628   4.753249 -1064.392 1079.648
#> 4    F002      2018 7.518 -11.242862 -1064.502 1079.538
#> 5    F002      2019 7.487  12.529649 -1064.533 1079.507
#> 6    F002      2020 7.165   5.620737 -1064.855 1079.185
```
