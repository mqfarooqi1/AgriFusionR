# Build a resampling scheme

Constructs the train and test splits used to estimate predictive skill.

## Usage

``` r
resample_scheme(
  p,
  method = c("spatial_block", "leave_location_out", "forward_season", "random"),
  k = 5,
  buffer = 0
)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  with features built.

- method:

  `"spatial_block"` groups units into compact blocks by k-means on their
  coordinates and holds out whole blocks; `"leave_location_out"` holds
  out whole units; `"forward_season"` trains on past seasons and tests
  on the next, never using the future to predict the past; `"random"`
  ignores structure entirely.

- k:

  Number of folds.

- buffer:

  Exclude training rows whose unit lies within this distance of any test
  unit. Kilometres when the project is geographic, otherwise coordinate
  units. Buffering removes the residual optimism that blocking alone
  leaves at block edges.

## Value

An object of class `agri_resample`.

## Why the default is spatial

Agricultural observations near one another share weather, soil and
management. Under random k-fold cross-validation a test point almost
always has a near-duplicate in the training set, so the estimate answers
"how well does this interpolate between my own plots" when the question
asked is usually "how well does this predict somewhere new". The gap
between the two is often large. Roberts et al. (2017) set out the
problem and the blocking remedies; Meyer and Pebesma (2021) show how far
a model can be trusted outside the space it was trained in.

`"random"` remains available, and
[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
reports both so the difference can be quantified rather than argued
about.

## References

Roberts, D. R. et al. (2017) "Cross-validation strategies for data with
temporal, spatial, hierarchical, or phylogenetic structure." Ecography
40, 913-929.
[doi:10.1111/ecog.02881](https://doi.org/10.1111/ecog.02881)

Meyer, H. & Pebesma, E. (2021) "Predicting into unknown space?
Estimating the area of applicability of spatial prediction models."
Methods in Ecology and Evolution 12, 1620-1633.
[doi:10.1111/2041-210X.13650](https://doi.org/10.1111/2041-210X.13650)

## See also

[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 2))
p <- add_climate(p, source = "demo")
p <- phenology_windows(p)
p <- build_features(p)
resample_scheme(p, method = "spatial_block", k = 3)
#> <agri_resample>
#>   method : spatial_block 
#>   folds  : 3 
#>   test n : 8, 8, 8 
```
