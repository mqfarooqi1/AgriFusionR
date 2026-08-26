# Changelog

## AgriFusionR 0.1.0

CRAN release: 2026-08-26

- Eight more learners: `glm`, `knn`, `xgboost`, `cubist`, `enet`, `svm`,
  `gam`, and `stack`, a stacked ensemble weighted by non-negative least
  squares, with
  [`stack_weights()`](https://mqfarooqi1.github.io/AgriFusionR/reference/stack_weights.md)
  to report the contributions. Ten in total.
- Learners are tested for signal recovery *and* row alignment, so an
  adapter that runs but predicts nonsense fails rather than passing
  quietly.
- Three more explanation methods: accumulated local effects (Apley and
  Zhu 2020), ICE curves, and exact tree SHAP via `treeshap`.
- Five remote data sources: CHIRPS, Daymet, WorldClim, SoilGrids, and
  SRTM elevation with slope and aspect. CHIRPS defaults to the
  ClimateSERV backend, because the CHC Cloud Optimized GeoTIFF path
  failed with GDAL tile-read errors on point queries.
- Visualisation layer in base graphics, so it adds no dependency:
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  `agri_project`, `agri_resample` and `agri_model`, plus
  [`plot_map()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_map.md)
  (prediction, residual and error surfaces),
  [`plot_effect()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_effect.md)
  (ALE, PDP, ICE) and
  [`plot_uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_uncertainty.md)
  (interval coverage). Colour scales come from
  [`hcl.colors()`](https://rdrr.io/r/grDevices/palettes.html) and are
  safe for colour vision deficiency.
- 219 tests; `R CMD check` clean.

## AgriFusionR 0.0.0.9000

Pre-release development.

- [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md)
  keyed on management unit and season, with role detection, a
  duplicate-key validator and a provenance ledger.
- Source and learner registries
  ([`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md),
  [`register_learner()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_learner.md))
  as the extension mechanism.
- [`growing_degree_days()`](https://mqfarooqi1.github.io/AgriFusionR/reference/growing_degree_days.md)
  and
  [`phenology_windows()`](https://mqfarooqi1.github.io/AgriFusionR/reference/phenology_windows.md)
  for thermal-time staging; indicative thermal parameters for six crops
  in
  [`crop_parameters()`](https://mqfarooqi1.github.io/AgriFusionR/reference/crop_parameters.md).
- [`build_features()`](https://mqfarooqi1.github.io/AgriFusionR/reference/build_features.md)
  aggregating daily layers over phenological stages, with calendar and
  whole-season alternatives for comparison, plus heat, frost and
  dry-spell counters.
- [`check_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/check_project.md)
  including a leakage guard that refuses covariate windows reaching past
  the harvest they predict.
- [`resample_scheme()`](https://mqfarooqi1.github.io/AgriFusionR/reference/resample_scheme.md)
  with spatial blocking, leave-location-out, forward-season and buffered
  variants; spatial blocking is the default.
- [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
  reporting spatial and random cross-validation side by side so the
  optimism of random folds is quantified.
- [`uncertainty()`](https://mqfarooqi1.github.io/AgriFusionR/reference/uncertainty.md)
  giving split-conformal prediction intervals with a non-circular
  coverage estimate.
- [`explain()`](https://mqfarooqi1.github.io/AgriFusionR/reference/explain.md)
  with out-of-fold permutation importance and partial dependence.
- [`report()`](https://mqfarooqi1.github.io/AgriFusionR/reference/report.md)
  writing a model card whose limitations section is generated from the
  model’s own diagnostics.
- Offline, deterministic demonstration system with a known
  data-generating process; 111 tests.
