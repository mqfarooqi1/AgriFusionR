# Accessors for project components

Accessors for project components

## Usage

``` r
units_of(p)

seasons_of(p)

provenance(p)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md).

## Value

`units_of()` returns one row per management unit with its coordinates;
`seasons_of()` one row per unit and season with the growing window;
`provenance()` the ledger of operations applied so far.

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
units_of(p)
#>   unit_id   x  y
#> 1    F001 -95 39
#> 2    F002 -88 39
#> 3    F003 -95 44
#> 4    F004 -88 44
head(seasons_of(p))
#>   unit_id season_id      start        end  crop
#> 1    F001      2018 2018-04-30 2018-10-16 maize
#> 2    F002      2018 2018-04-30 2018-10-16 maize
#> 3    F003      2018 2018-05-08 2018-10-24 maize
#> 4    F004      2018 2018-05-08 2018-10-24 maize
#> 5    F001      2019 2019-04-30 2019-10-16 maize
#> 6    F002      2019 2019-04-30 2019-10-16 maize
```
