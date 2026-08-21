# Train and honestly validate a model

Fits a model to predict `target` from the features built for the
project, estimating skill by spatial resampling rather than random
folds.

## Usage

``` r
train_model(
  p,
  target,
  algorithm = "auto",
  resampling = NULL,
  method = "spatial_block",
  k = 5,
  buffer = 0,
  compare_random = TRUE,
  ...
)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  with features built.

- target:

  Name of the response column in the project's observations.

- algorithm:

  A registered learner, or `"auto"` to use `"ranger"` when available and
  `"lm"` otherwise. See
  [`list_learners()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md).

- resampling:

  A
  [`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md)
  object. Built automatically when `NULL`.

- method, k, buffer:

  Passed to
  [`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md)
  when it builds the scheme itself.

- compare_random:

  Also evaluate with random folds, to quantify the optimism that random
  cross-validation would have introduced.

- ...:

  Passed to the learner's `fit` function.

## Value

An object of class `agri_model`.

## Details

By default the same model is also evaluated with random folds and both
results are reported. The difference between them is the amount by which
random cross-validation would have overstated the model, and it is worth
knowing before any figure is published.

Missing predictor values are filled with the median of the training rows
of each fold, computed inside the fold so that no information crosses
the split.

## See also

[`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md),
[`explain()`](https://mqfarooqi1.github.io/AgriFusionR/reference/explain.md),
[`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md),
[`report()`](https://mqfarooqi1.github.io/AgriFusionR/reference/report.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
p <- add_climate(p, source = "demo")
p <- phenology_windows(p)
p <- build_features(p)
m <- train_model(p, target = "yield", algorithm = "lm", k = 3)
#> Warning: 64 features for 36 observations. Unregularised linear learners will be rank deficient here; prefer a tree-based or penalised learner, or pass fewer `stats` to build_features().
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
m
#> <agri_model>
#>   target     : yield 
#>   learner    : lm 
#>   features   : 64 
#>   resampling : spatial_block (3 folds) 
#>   spatial CV : RMSE 584.939  MAE 339.920  R2 -869544.922  (n=36)
#>   random CV  : RMSE 23.243  MAE 7.477  R2 -1372.005
#>   optimism   : random CV overstates R2 by 868172.917
```
