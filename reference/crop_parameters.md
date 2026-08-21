# Indicative crop thermal parameters

Base and upper temperatures, and cumulative growing degree days at the
end of each phenological stage, for a small set of crops.

## Usage

``` r
crop_parameters(crop = NULL)
```

## Arguments

- crop:

  Optional crop name. When `NULL`, all crops are returned.

## Value

A data frame with columns `crop`, `t_base`, `t_upper`, `stage` and
`gdd_end`, ordered by crop and cumulative thermal time.

## Calibrate before trusting

These values are **indicative defaults for getting started, not
calibrated constants**. Thermal requirements vary substantially with
cultivar, photoperiod and region, and a stage boundary that is wrong by
a fortnight will misattribute the weather a model sees. Supply your own
thresholds through the `stages` argument of
[`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)
for any analysis you intend to publish.

## See also

[`growing_degree_days()`](https://mqfarooqi1.github.io/AgriFusionR/reference/growing_degree_days.md),
[`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)

## Examples

``` r
crop_parameters("wheat")
#>    crop t_base t_upper           stage gdd_end
#> 1 wheat      0      30       emergence     150
#> 2 wheat      0      30       tillering     500
#> 3 wheat      0      30 stem_elongation     900
#> 4 wheat      0      30        anthesis    1300
#> 5 wheat      0      30      grain_fill    1900
#> 6 wheat      0      30        maturity    2200
unique(crop_parameters()$crop)
#> [1] "wheat"   "maize"   "rice"    "soybean" "canola"  "generic"
```
