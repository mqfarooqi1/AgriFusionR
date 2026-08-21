# Growing degree days

Daily thermal time by the capped-average method: the mean of the daily
maximum and minimum, each first constrained to the interval between the
base and upper temperatures, less the base temperature, with negative
values set to zero.

## Usage

``` r
growing_degree_days(tmin, tmax, t_base = 5, t_upper = Inf)
```

## Arguments

- tmin, tmax:

  Numeric vectors of daily minimum and maximum temperature in degrees
  Celsius.

- t_base:

  Base temperature below which development is taken to stop.

- t_upper:

  Temperature above which further warmth adds no development.

## Value

A numeric vector of daily growing degree days, never negative.

## Details

This is the interpretation McMaster and Wilhelm (1997) label Method 1
with a horizontal cut-off. The choice matters: the two common
interpretations of the same equation can differ by hundreds of degree
days over a season, so the method is stated rather than left implicit.

## References

McMaster, G. S. & Wilhelm, W. W. (1997) "Growing degree-days: one
equation, two interpretations." Agricultural and Forest Meteorology 87,
291-300.
[doi:10.1016/S0168-1923(97)00027-0](https://doi.org/10.1016/S0168-1923%2897%2900027-0)

## See also

[`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md),
[`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)

## Examples

``` r
growing_degree_days(tmin = c(4, 8, 12), tmax = c(18, 24, 33), t_base = 5)
#> [1]  6.5 11.0 17.5
```
