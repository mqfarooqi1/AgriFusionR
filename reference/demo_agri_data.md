# A demonstration agricultural data set

Generates a multi-field, multi-season data set whose yields are produced
by a known process, for examples, tests and teaching.

## Usage

``` r
demo_agri_data(n_units = 40, n_seasons = 4, crop = "maize", start_year = 2018)
```

## Arguments

- n_units:

  Number of management units.

- n_seasons:

  Number of seasons per unit.

- crop:

  Crop name, used for thermal parameters.

- start_year:

  First season.

## Value

A data frame with one row per unit and season, containing coordinates,
the growing window, soil clay, yield, and the true driver values used to
build it.

## Details

The data are **simulated, not observed**. Yield is built from rainfall
accumulated during grain fill, the count of days above 30 degrees during
silking, soil clay content, a smooth spatial trend and a season effect.
Because those drivers are known exactly, an analysis of this data set
can be checked against the truth rather than against a previous run.

Generation is deterministic: no random number generator is used and the
global RNG state is not touched, so repeated calls return identical
data.

## See also

[`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md),
[`add_climate()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)

## Examples

``` r
d <- demo_agri_data(n_units = 6, n_seasons = 2)
str(d)
#> 'data.frame':    12 obs. of  11 variables:
#>  $ unit_id       : chr  "F001" "F002" "F003" "F004" ...
#>  $ lon           : num  -95 -91.5 -88 -95 -91.5 -88 -95 -91.5 -88 -95 ...
#>  $ lat           : num  39 39 39 41.5 41.5 41.5 39 39 39 41.5 ...
#>  $ season        : num  2018 2018 2018 2018 2018 ...
#>  $ planting      : Date, format: "2018-04-30" "2018-04-30" ...
#>  $ harvest       : Date, format: "2018-10-16" "2018-10-16" ...
#>  $ crop          : chr  "maize" "maize" "maize" "maize" ...
#>  $ clay          : num  36.7 34.1 17.3 42.4 39.8 23 36.7 34.1 17.3 42.4 ...
#>  $ yield         : num  7.98 7.21 7.07 8.68 7.83 ...
#>  $ true_gf_rain  : num  9.7 10.7 11.8 44.5 48.8 42.8 8.4 9.2 10.1 51.5 ...
#>  $ true_heat_days: int  15 15 15 13 14 14 16 16 15 13 ...
```
