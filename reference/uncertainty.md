# Prediction intervals by split conformal inference

Turns the out-of-fold residuals into prediction intervals with a
distribution-free finite-sample coverage guarantee.

## Usage

``` r
uncertainty(object, level = 0.9, ...)

# S3 method for class 'agri_model'
uncertainty(object, level = 0.9, ...)
```

## Arguments

- object:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md).

- level:

  Target coverage, between 0 and 1.

- ...:

  Ignored.

## Value

An object of class `agri_uncertainty` giving the interval half-width,
the target level and the estimated empirical coverage.

## Details

Conformal inference is used because it is the only interval method that
works uniformly across a registry of arbitrary learners: it assumes
nothing about the model or the error distribution, only that the
calibration and prediction data are exchangeable. Because the residuals
come from **spatial** resampling, the resulting intervals inherit that
honesty; intervals calibrated on random folds would be too narrow for
the same reason random cross-validation is too optimistic.

## Reported coverage

The half-width and the coverage check cannot come from the same
residuals without being circular. Coverage is therefore estimated by
two-fold splitting of the residual vector: calibrate on one half,
measure on the other, and average the two directions.

## References

Lei, J., G'Sell, M., Rinaldo, A., Tibshirani, R. J. & Wasserman, L.
(2018) "Distribution-free predictive inference for regression." Journal
of the American Statistical Association 113, 1094-1111.
[doi:10.1080/01621459.2017.1307116](https://doi.org/10.1080/01621459.2017.1307116)

## See also

[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md),
[`predict.agri_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/predict.agri_model.md)

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
uncertainty(m)
#> <agri_uncertainty>
#>   target        : yield 
#>   level         : 0.9 
#>   half-width    : 1072.0203  (interval is prediction +/- this)
#>   calibration n : 36 
#>   coverage      : 0.972 estimated by split (target 0.90)
```
