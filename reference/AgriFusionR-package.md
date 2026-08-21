# AgriFusionR: an integration framework for agricultural analytics

R is already well supplied with machine learning, geospatial and
agronomic packages. What it lacks is the layer that joins them: a single
object that holds a management unit and its season, keeps climate, soil
and remote-sensing covariates aligned to it, aggregates them over the
crop's phenology rather than the calendar, and validates the result in a
way that survives spatial autocorrelation. That layer is what this
package provides.

## Getting started

[`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
builds the object;
[`add_climate()`](https://mqfarooqi1.github.io/AgriFusionR/reference/add_layer.md)
and its siblings attach covariates;
[`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)
derives thermal-time stages;
[`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)
reduces everything to one row per unit and season;
[`check_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/check_project.md)
looks for leakage and other faults;
[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
fits and validates;
[`explain()`](https://mqfarooqi1.github.io/AgriFusionR/reference/explain.md),
[`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md)
and
[`report()`](https://mqfarooqi1.github.io/AgriFusionR/reference/report.md)
interpret.

## Extending it

[`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md)
and
[`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md)
add data providers and algorithms without modifying the package.

## See also

Useful links:

- <https://github.com/mqfarooqi1/AgriFusionR>

- Report bugs at <https://github.com/mqfarooqi1/AgriFusionR/issues>

## Author

**Maintainer**: Muhammad Farooqi <mqfarooqi@gmail.com>
([ORCID](https://orcid.org/0000-0003-4918-9791))

Authors:

- Muhammad Farooqi <mqfarooqi@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-4918-9791))
