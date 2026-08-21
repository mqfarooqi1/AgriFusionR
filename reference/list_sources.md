# List registered sources and learners

List registered sources and learners

## Usage

``` r
list_sources()

list_learners()
```

## Value

A data frame describing what is currently registered.

## See also

[`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md),
[`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md)

## Examples

``` r
list_sources()
#>        name   kind                 provides network
#> 1      demo series         tmin, tmax, prcp   FALSE
#> 2 demo_soil static               clay, sand   FALSE
#> 3     power series         tmin, tmax, prcp    TRUE
#> 4    chirps series                     prcp    TRUE
#> 5    daymet series   tmin, tmax, prcp, srad    TRUE
#> 6 worldclim static                     wc_*    TRUE
#> 7 soilgrids static   clay, sand, soc, phh2o    TRUE
#> 8 elevation static elevation, slope, aspect    TRUE
#>                                            description
#> 1       Deterministic synthetic daily weather, offline
#> 2        Deterministic synthetic soil texture, offline
#> 3     NASA POWER daily agroclimatology via 'nasapower'
#> 4       CHIRPS daily rainfall via the 'chirps' package
#> 5   Daymet daily weather, North America, via 'daymetr'
#> 6              WorldClim climate normals via 'geodata'
#> 7              SoilGrids soil properties via 'geodata'
#> 8 SRTM elevation and terrain derivatives via 'geodata'
list_learners()
#>       name requires
#> 1       lm         
#> 2      glm         
#> 3      knn         
#> 4   ranger   ranger
#> 5  xgboost  xgboost
#> 6   cubist   Cubist
#> 7     enet   glmnet
#> 8      svm  kernlab
#> 9      gam     mgcv
#> 10   stack         
#>                                                                                description
#> 1                                                 Ordinary least squares; always available
#> 2                                     Generalised linear model; pass `family` to change it
#> 3                                          k nearest neighbours on standardised predictors
#> 4                                                               Random forest via 'ranger'
#> 5                                                          Gradient boosting via 'xgboost'
#> 6                                                      Rule-based model trees via 'Cubist'
#> 7                                   Elastic net with lambda by cross-validation ('glmnet')
#> 8                                                  Support vector regression via 'kernlab'
#> 9                                                    Generalised additive model via 'mgcv'
#> 10 Stacked ensemble of the available base learners, weighted by non-negative least squares
```
