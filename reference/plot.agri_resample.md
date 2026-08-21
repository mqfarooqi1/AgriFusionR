# Plot a resampling scheme

Draws each unit coloured by the fold it is held out in, so that what the
blocking actually did can be seen rather than assumed. Blocks that look
interleaved are not blocking anything.

## Usage

``` r
# S3 method for class 'agri_resample'
plot(x, ...)
```

## Arguments

- x:

  An
  [`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md)
  object.

- ...:

  Passed to `plot`.

## Value

`x`, invisibly. Called for the plot.

## See also

[`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md),
[`plot.agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot.agri_project.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 24, n_seasons = 2))
p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
plot(resample_scheme(p, method = "spatial_block", k = 4))
```
