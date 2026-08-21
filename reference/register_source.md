# Register a covariate source

Adds a data provider to the source registry, making it available to
[`add_climate()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md),
[`add_soil()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
and
[`add_satellite()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md).
This is the extension point for new providers: no change to the package
is needed.

## Usage

``` r
register_source(
  name,
  fetch,
  provides,
  kind = c("series", "static"),
  requires_network = TRUE,
  description = ""
)
```

## Arguments

- name:

  Name used to select the source, for example `"power"`.

- fetch:

  A function with signature `function(units, seasons, ...)` returning a
  data frame. Series sources must return one row per unit and date, with
  columns `unit_id` and `date`; static sources one row per unit, with
  column `unit_id`.

- provides:

  Character vector of the variables the source returns.

- kind:

  Either `"series"` for time-varying data or `"static"` for values fixed
  within a unit.

- requires_network:

  Whether the source needs internet access. Sources that do are skipped
  in tests and examples.

- description:

  A one-line human description.

## Value

Invisibly, the registered name.

## See also

[`list_sources()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md),
[`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md)

## Examples

``` r
register_source("flat",
                fetch = function(units, seasons, ...) {
                    data.frame(unit_id = units$unit_id, elevation = 100)
                },
                provides = "elevation", kind = "static",
                requires_network = FALSE)
"flat" %in% list_sources()$name
#> [1] TRUE
```
