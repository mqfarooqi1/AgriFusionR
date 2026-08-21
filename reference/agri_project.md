# Create an agricultural analysis project

Builds the object every other function in the package operates on. The
unit of observation is a **management unit within a season**: a field,
plot or administrative area, together with the window over which the
crop grew. Each observation is keyed by `(unit_id, season_id)`, and
every covariate layer added later must reduce to that key.

## Usage

``` r
agri_project(
  data,
  unit_id = NULL,
  x = NULL,
  y = NULL,
  season = NULL,
  start = NULL,
  end = NULL,
  crop = NULL,
  crs = 4326,
  cache_dir = NULL
)
```

## Arguments

- data:

  A data frame with one row per management unit and season.

- unit_id, x, y:

  Column names giving the unit identifier and its coordinates. Detected
  from names such as `unit_id`, `field`, `lon`, `lat` when `NULL`.

- season:

  Column naming the season, typically a year. Detected from `season` or
  `year`.

- start, end:

  Columns giving the start and end of the growing window as dates.
  Detected from names such as `planting`/`sowing` and `harvest`.

- crop:

  Column giving the crop, if more than one is present.

- crs:

  Coordinate reference system as an EPSG code. Only 4326 is currently
  treated as geographic; anything else is taken as projected, which
  changes how distances are computed.

- cache_dir:

  Directory for cached downloads. Defaults to a session temporary
  directory, so nothing is written outside it unless asked.

## Value

An object of class `agri_project`.

## Details

Column roles are detected from common names when not given explicitly,
so `agri_project(data)` usually works unchanged. Detection is reported
by the print method, and can always be overridden.

## See also

[`add_climate()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md),
[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md),
[`check_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/check_project.md)

## Examples

``` r
d <- demo_agri_data(n_units = 6, n_seasons = 2)
p <- agri_project(d)
p
#> <agri_project>
#>   observations : 12 
#>   units        : 6 (unit_id) 
#>   seasons      : 2 (season) 
#>   window       : 2018-04-30 to 2019-10-20 
#>   extent       : x [-95.000, -88.000]  y [39.000, 41.500] 
#>   layers       : none 
#>   windows      : not derived 
#>   features     : not built 
```
