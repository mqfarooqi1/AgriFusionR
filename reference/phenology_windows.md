# Derive phenological windows from accumulated thermal time

Labels every day of every growing season with the phenological stage the
crop had reached by that date, based on accumulated growing degree days,
and summarises the resulting windows.

## Usage

``` r
phenology_windows(
  p,
  crop = NULL,
  stages = NULL,
  t_base = NULL,
  t_upper = NULL,
  layer = "climate"
)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  with a climate layer providing `tmin` and `tmax`.

- crop:

  Crop name used to look up thermal parameters. When `NULL`, the
  project's crop column is used if present, otherwise `"generic"`.

- stages:

  Optional data frame of custom thresholds with columns `stage` and
  `gdd_end`, overriding
  [`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md).

- t_base, t_upper:

  Optional overrides for the base and upper temperatures.

- layer:

  Name of the climate layer to read.

## Value

The project, with daily stage labels attached to the climate layer and a
window summary available as `p$windows`.

## Details

Aligning covariates to phenology rather than to the calendar is the
point of the exercise. "Rainfall in September" means different things to
two crops sown six weeks apart; "rainfall during grain fill" means the
same thing to both. Aggregation in
[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)
uses these labels.

## See also

[`growing_degree_days()`](https://mqfarooqi1.github.io/AgriFusionR/reference/growing_degree_days.md),
[`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md),
[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
p <- add_climate(p, source = "demo")
p <- phenology_windows(p)
head(p$windows)
#>   unit_id season_id      stage      start        end days  gdd_end
#> 1    F001      2018  emergence 2018-04-30 2018-05-14   15   96.135
#> 2    F001      2018 vegetative 2018-05-15 2018-06-20   37  486.725
#> 3    F001      2018    silking 2018-06-21 2018-07-21   31  887.670
#> 4    F001      2018 grain_fill 2018-07-22 2018-08-29   39 1394.915
#> 5    F001      2018   maturity 2018-08-30 2018-10-16   48 1731.210
#> 6    F001      2019  emergence 2019-04-30 2019-05-16   17   99.925
```
