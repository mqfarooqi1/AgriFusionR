# Attach a covariate layer to a project

Fetches covariates from a registered source and attaches them to the
project, keyed to the management unit and season. `add_climate()`,
`add_soil()` and `add_satellite()` differ only in the layer they write
to and the sources they expect; all three are thin calls to the source
registry, so a source added with
[`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md)
is usable immediately.

## Usage

``` r
add_layer(p, source, layer, overwrite = FALSE, ...)

add_climate(p, source = "demo", layer = "climate", overwrite = FALSE, ...)

add_soil(p, source = "demo_soil", layer = "soil", overwrite = FALSE, ...)

add_satellite(p, source, layer = "satellite", overwrite = FALSE, ...)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md).

- source:

  Name of a registered source. See
  [`list_sources()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md).

- layer:

  Name to store the layer under.

- overwrite:

  Replace an existing layer of the same name.

- ...:

  Passed to the source's `fetch` function.

## Value

The project, with the layer attached and the operation recorded in its
provenance.

## Details

Nothing is fetched twice: a layer already present is returned unchanged
unless `overwrite = TRUE`.

## See also

[`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md),
[`list_sources()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md),
[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
p <- add_climate(p, source = "demo")
names(p$layers)
#> [1] "climate"
head(p$layers$climate$data)
#>   unit_id season_id       date  tmax  tmin prcp
#> 1    F001      2018 2018-04-30 25.49 15.07    0
#> 2    F001      2018 2018-05-01 25.36 14.13    0
#> 3    F001      2018 2018-05-02 25.06 13.03    0
#> 4    F001      2018 2018-05-03 24.61 11.85    0
#> 5    F001      2018 2018-05-04 24.01 10.66    0
#> 6    F001      2018 2018-05-05 23.30  9.54    0
```
