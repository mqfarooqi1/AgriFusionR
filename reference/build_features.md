# Build the model design matrix

Reduces every attached layer to one row per management unit and season,
which is the key the whole package is organised around.

## Usage

``` r
build_features(
  p,
  aggregation = c("phenology", "monthly", "season"),
  stats = c("mean", "sum", "min", "max"),
  stress = TRUE,
  heat_threshold = 30,
  dry_threshold = 1
)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  with at least one layer attached. For `aggregation = "phenology"`,
  [`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)
  must have been run.

- aggregation:

  How to group days within a season.

- stats:

  Statistics to compute for each variable and group.

- stress:

  Whether to derive stress-day counters.

- heat_threshold:

  Daily maximum temperature, in degrees Celsius, above which a day
  counts as heat stress.

- dry_threshold:

  Daily rainfall, in millimetres, below which a day counts as dry.

## Value

The project, with `features` populated.

## Details

Daily layers are aggregated within phenological stage by default, so
that a feature such as `prcp_sum_grain_fill` carries the same meaning
across sites that sowed weeks apart. Aggregating by calendar month
instead is available for comparison, and is the usual practice in the
literature; it is offered so the difference can be measured rather than
assumed.

Stress counters are derived before aggregation: days above the heat
threshold, days below freezing, dry days, and the longest dry spell in
the season.

## See also

[`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md),
[`check_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/check_project.md),
[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 6, n_seasons = 2))
p <- add_climate(p, source = "demo")
p <- phenology_windows(p)
p <- build_features(p)
dim(p$features)
#> [1] 12 66
```
