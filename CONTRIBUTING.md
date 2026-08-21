# Contributing to AgriFusionR

Contributions are welcome. The package is at an early stage, so the most
useful contributions right now are the ones that test the design against
real problems.

## Ways to help that are genuinely useful

**Try it on your data and report what broke.** The package is currently
validated on one simulated system and one real data set. Every new data
set is a chance to find a wrong assumption. Open an issue with what you
tried and what happened.

**Add a data source.** Providers are a function plus one registration
call, and need no change to the package:

``` r

register_source("my_provider",
                fetch = function(units, seasons, ...) {
                    # series: one row per unit_id, season_id and date
                    # static: one row per unit_id
                },
                provides = c("tmin", "tmax"),
                kind = "series")
```

**Add a learner.** Same pattern with
[`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md).
Please wrap an existing, maintained implementation rather than writing a
new one.

**Calibrate crop parameters.** The thermal thresholds in
[`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md)
are indicative defaults. Locally calibrated values, with a citation, are
worth more than any amount of new code.

## What is out of scope

Reimplementations of things CRAN already does well: learners,
cross-validation algorithms, raster IO, satellite access. This package
is an integration layer and delegates on purpose. See `ARCHITECTURE.md`
for the reasoning.

## Practical matters

- Every change needs a test. Tests must pass offline and must not
  require network access; gate anything that does with
  `skip_if_not_installed()` or `skip_on_cran()`.
- `R CMD check` must stay clean, with no new warnings or notes.
- Keep `Imports` free of heavy dependencies. Optional packages belong in
  `Suggests` behind
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).
- Style: four-space indents, lines under 80 characters, `snake_case`.
- Run before opening a pull request:

``` r

devtools::document()
devtools::test()
devtools::check()
```

## Reporting a bug

A reproducible example matters more than a description. If the data are
not shareable,
[`demo_agri_data()`](https://mqfarooqi1.github.io/AgriFusionR/reference/demo_agri_data.md)
generates a deterministic data set that often reproduces structural
problems just as well.

## Code of conduct

Be civil and assume good faith. Disagreement about methods is welcome
and expected; disparagement of people is not.
