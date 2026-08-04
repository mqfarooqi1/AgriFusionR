# AgriFusionR 0.0.0.9000 (Phase 2)

* Eight more learners: `glm`, `knn`, `xgboost`, `cubist`, `enet`, `svm`, `gam`,
  and `stack`, a stacked ensemble weighted by non-negative least squares, with
  `stack_weights()` to report the contributions. Ten in total.
* Learners are tested for signal recovery *and* row alignment, so an adapter
  that runs but predicts nonsense fails rather than passing quietly.
* Three more explanation methods: accumulated local effects (Apley and Zhu
  2020), ICE curves, and exact tree SHAP via `treeshap`.
* Five remote data sources: CHIRPS, Daymet, WorldClim, SoilGrids, and SRTM
  elevation with slope and aspect. CHIRPS defaults to the ClimateSERV backend,
  because the CHC Cloud Optimized GeoTIFF path failed with GDAL tile-read
  errors on point queries.
* Visualisation layer in base graphics, so it adds no dependency:
  `plot()` methods for `agri_project`, `agri_resample` and `agri_model`, plus
  `plot_map()` (prediction, residual and error surfaces), `plot_effect()`
  (ALE, PDP, ICE) and `plot_uncertainty()` (interval coverage). Colour scales
  come from `hcl.colors()` and are safe for colour vision deficiency.
* 219 tests; `R CMD check` clean.

# AgriFusionR 0.0.0.9000

Phase 0: design and core spine. Nothing is released.

* `agri_project()` keyed on management unit and season, with role detection,
  a duplicate-key validator and a provenance ledger.
* Source and learner registries (`register_source()`, `register_learner()`) as
  the extension mechanism.
* `growing_degree_days()` and `phenology_windows()` for thermal-time staging;
  indicative thermal parameters for six crops in `crop_parameters()`.
* `build_features()` aggregating daily layers over phenological stages, with
  calendar and whole-season alternatives for comparison, plus heat, frost and
  dry-spell counters.
* `check_project()` including a leakage guard that refuses covariate windows
  reaching past the harvest they predict.
* `resample_scheme()` with spatial blocking, leave-location-out, forward-season
  and buffered variants; spatial blocking is the default.
* `train_model()` reporting spatial and random cross-validation side by side so
  the optimism of random folds is quantified.
* `uncertainty()` giving split-conformal prediction intervals with a
  non-circular coverage estimate.
* `explain()` with out-of-fold permutation importance and partial dependence.
* `report()` writing a model card whose limitations section is generated from
  the model's own diagnostics.
* Offline, deterministic demonstration system with a known data-generating
  process; 111 tests.
