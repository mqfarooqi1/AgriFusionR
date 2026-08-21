# Check a project for the faults that invalidate an analysis

Runs the checks that are cheap to automate and expensive to discover
late.

## Usage

``` r
check_project(p, mad_k = 3, max_missing = 0.2)
```

## Arguments

- p:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md).

- mad_k:

  Number of median absolute deviations beyond which a value is flagged.
  Three is conventional.

- max_missing:

  Proportion of missing values in a feature above which it is reported.

## Value

A data frame of issues with columns `severity`, `check` and `detail`,
invisibly returned and printed. Zero rows means every check passed.

## Details

The most important is the **leakage guard**: a covariate window that
extends past the harvest it is supposed to predict produces a model that
cannot be deployed and a skill estimate that means nothing. It is easy
to introduce by fetching a fixed date range for every site, and hard to
see afterwards.

Also checked: duplicated unit-season keys, coordinates outside plausible
bounds, missingness by column, and univariate outliers by the median
absolute deviation, which is resistant to the outliers it is looking
for.

## See also

[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md),
[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 6, n_seasons = 2))
p <- add_climate(p, source = "demo")
check_project(p)
#> check_project(): no issues found.
```
