# Stack weights from a fitted ensemble

Reports how much each base learner contributed to a `"stack"` model,
which is usually more informative than the ensemble's accuracy alone: a
stack that puts all its weight on one learner is telling you the others
added nothing.

## Usage

``` r
stack_weights(model)
```

## Arguments

- model:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
  with `algorithm = "stack"`.

## Value

A named numeric vector of weights summing to one.

## See also

[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md),
[`list_learners()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 14, n_seasons = 3))
p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
set.seed(1)
m <- train_model(p, "yield", algorithm = "stack", k = 3,
                 compare_random = FALSE)
#> Warning: 24 features for 42 observations. Unregularised linear learners will be rank deficient here; prefer a tree-based or penalised learner, or pass fewer `stats` to build_features().
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
stack_weights(m)
#>      ranger        enet      cubist         knn 
#> 0.990703715 0.000000000 0.009296285 0.000000000 
```
