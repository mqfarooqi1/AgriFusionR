# AgriFusionR — Architecture and Design Rationale

**Status:** Phase 0 (design + core spine). Not released. Not published.
**Author:** Muhammad Farooqi
**Last revised:** 2026-08-04

---

## 1. What the landscape actually looks like

Before designing anything I enumerated CRAN (24,462 packages on 2026-08-04) for
every capability this framework was asked to provide. The result decides the
design, so it is recorded in full.

| Capability | Already on CRAN |
|---|---|
| Spatial / spatiotemporal CV | `blockCV`, `CAST`, `sperrorest`, `spatialsample`, `mlr3spatiotempcv` |
| ML frameworks | `tidymodels`, `mlr3`, `caret` (+ `parsnip`, `recipes`, `workflows`) |
| Learners | `ranger`, `xgboost`, `lightgbm`, `Cubist`, `glmnet`, `kernlab` |
| Deep learning | `torch`, `keras3`, `luz`, `brulee`, `tabnet` |
| Geospatial core | `sf`, `terra`, `stars`, `gdalcubes`, `rstac`, `exactextractr` |
| Geostatistics / GWR | `gstat`, `automap`, `GWmodel`, `spgwr`, `fields` |
| Bayesian | `brms`, `rstan`, `spBayes` |
| Explainable AI | `iml`, `DALEX`, `shapviz`, `pdp`, `treeshap` |
| Climate ingestion | `nasapower`, `chirps`, `daymetr`, `geodata`, `ecmwfr`, `easyclimate`, `climate` |
| Earth observation | `rgee`, `rsi`, `sits` |
| Soil | `soilDB`, `aqp`, `soiltexture`, `SoilR` |
| Crop / agronomy | `apsimx`, `DSSAT`, `Recocrop`, `AquaBEHER`, `CropWaterBalance`, `SPEI`, `phenofit`, `agridat`, `metan` |

Two packages I had expected to lean on — `fastshap` and `vip` — are **not
currently on CRAN**, so the explainability layer targets `iml` / `DALEX` /
`treeshap` / `pdp` instead. Checking rather than assuming saved a broken
`Suggests`.

### 1.1 The conclusion this forces

**R does not lack agricultural machine-learning capability. It lacks an
integration layer.** Every individual component in the original brief already
exists, usually in a mature, well-maintained, better-tested form than a new
project could reach for years.

Therefore a framework that reimplements learners, cross-validation algorithms,
raster IO, or satellite access would be *strictly worse than the status quo*. It
would be a wrapper with a new name — precisely the outcome the brief said to
avoid, arrived at from the opposite direction.

---

## 2. The real gap

What an agricultural analyst actually does, and what no package does for them:

1. **Assemble** a design matrix keyed by *management unit × season* from
   sources on different grids, calendars, projections and latencies.
2. **Align** covariates to the crop's **phenological** timeline rather than the
   calendar, so that "rainfall during grain fill" means the same thing in two
   places that sowed six weeks apart.
3. **Validate** the model in a way that survives spatial autocorrelation.
4. **Record** enough provenance that the analysis can be rebuilt and defended.

Every one of these is currently hand-rolled per project, in scripts that are
rarely shared and almost never reproducible. That glue — not the models — is
the contribution.

### 2.1 The scientific claim worth making

Two methodological faults are pervasive in published agricultural ML:

- **Random k-fold CV under spatial autocorrelation**, which inflates apparent
  skill because near-duplicate neighbours straddle the train/test split
  (Roberts et al. 2017, *Ecography*, <doi:10.1111/ecog.02881>; Meyer & Pebesma
  2021, *MEE*, <doi:10.1111/2041-210X.13650>).
- **Calendar-based covariate aggregation**, which smears weather across
  phenological stages of differing sensitivity.

A framework whose *defaults* make both faults hard to commit is a genuine,
narrow, testable contribution. This is a "pit of success" design: the easy path
must be the correct one. That claim is also empirically demonstrable — the
random-CV versus spatial-CV skill gap can be measured and reported.

**This, not breadth, is the reason for the package to exist.**

---

## 3. Architecture

```
 L5  Reporting        report()      model cards · methods text · provenance ledger
 L4  Interpretation   explain()     importance · PDP/ICE/ALE
                      uncertainty() conformal · quantile · ensemble spread
 L3  Learning         train_model() learner registry · resampling policy
 L2  Features         build_features()  phenology windows · aggregation
                      qc            validation · leakage guard · outliers
 L1  Ingestion        add_climate() add_soil() add_satellite()
                      source registry · content-addressed cache · harmonisation
 L0  Core             agri_project  units · seasons · targets · management
                      provenance ledger
```

### 3.1 The central abstraction

The unit of analysis in agriculture is not a raster cell and not a row of a
table. It is a **management unit observed over a season**:

```
(unit_id, season_id) -> { geometry/coords, [start, end], crop, management, target }
```

Every layer, whatever its native grid or calendar, must reduce to that key.
That single discipline is what makes the pipeline composable — and it is
enforced, not merely documented.

### 3.2 Plugin system

Three registries, populated at load and extensible by any package or user
script:

```r
register_source(name, fetch, provides, requires_network = TRUE)
register_learner(name, fit, predict, requires = character())
register_explainer(name, fn)
```

A new data provider or algorithm is a function plus one registration call. No
fork, no PR, no redesign — which is the "adaptable to future methods"
requirement, made concrete.

---

## 4. Design decisions, alternatives, and trade-offs

### D1 — Zero heavy hard dependencies

`Imports:` is `stats`, `utils`, `methods` **only**. `sf`, `terra`, `ranger`,
`nasapower` and everything else are `Suggests` behind capability detection.

- *Alternative:* depend directly on `sf`/`terra`/`tidymodels`.
- *Rejected because:* the GDAL/GEOS/PROJ toolchain makes installation fragile
  on exactly the machines extension agencies and students use, slows every CRAN
  check, and locks out users whose data is a spreadsheet of trial plots.
- *Trade-off accepted:* more `requireNamespace()` guarding, and both the
  present and absent paths must be tested.

### D2 — S3 with explicit validators, not S4 or R6

- *S4* is verbose and its dispatch buys nothing here (it is the right answer in
  a Bioconductor container; this is not one).
- *R6* has reference semantics that would silently break the
  `project <- add_climate(project)` idiom in the requested API.
- *S3 + `validate_*()`* preserves copy-on-modify, which is what the specified
  pipeline shape implies.

### D3 — Delegate; never reimplement

Learners are registry adapters. The resampling layer implements the *agronomic
policy* (which blocking, which buffer, which horizon) and emits plain index
sets interoperable with `rsample` and `mlr3`. With five mature spatial-CV
packages in existence, competing on the algorithm would destroy value; the
contribution is choosing the right scheme by default.

### D4 — Phenology-aligned aggregation as the default

Windows are derived from accumulated growing degree days (McMaster & Wilhelm
1997, *Agric. For. Meteorol.*, <doi:10.1016/S0168-1923(97)00027-0>) rather than
calendar months.

- *Trade-off:* requires a base temperature and stage thresholds per crop. These
  ship as **indicative defaults that are explicitly flagged as requiring local
  calibration** — a wrong default silently applied is worse than no default.

### D5 — Spatial CV by default; random CV opt-in and warned

The single most consequential decision in the package. `train_model()` refuses
to quietly use random folds on spatially referenced data.

### D6 — Lazy, content-addressed cache with provenance

Remote climate and EO fetches are slow, rate-limited, and *not stable over
time*. Caching by content hash plus a provenance ledger is what makes a
re-run in twelve months mean anything.

### D7 — Conformal prediction as the default interval method

Split conformal (Lei et al. 2018, *JASA*,
<doi:10.1080/01621459.2017.1307116>) is distribution-free, model-agnostic and
finite-sample valid — the only method that works uniformly across a registry of
arbitrary learners. Quantile-regression and Bayesian intervals are offered
where the learner supports them.

### D8 — Leakage guard as a first-class check

Automatic refusal when a covariate window extends past the harvest date of the
season it predicts, and when duplicate `(unit_id, season_id)` rows exist.

---

## 5. Phased roadmap

Deliberately measured in months. Scope expands only as validation accrues.

| Phase | Content | State |
|---|---|---|
| **0** | Core spine: project object, provenance, GDD/phenology, features, QC + leakage guard, resampling, one learner, conformal intervals, explain, report. Fully offline-capable and tested. | **this phase** |
| **1** | Real ingestion adapters, starting with `nasapower` (no auth required); soil via `soilDB`/`geodata`; harmonisation and cache hardening. | next |
| **2** | Raster and EO paths via `terra` + `rsi`/`rstac`; zonal extraction at scale; `gdalcubes` for time series. | |
| **3** | Uncertainty and XAI depth: quantile forests, ensemble spread, ALE, `DALEX`/`iml` adapters, model cards. | |
| **4** | Bayesian and geostatistical: `brms`, GPs, kriging residuals, GWR; causal-inference adapters. | |
| **5** | Deep learning via `torch`/`luz`; sequence models where evidence justifies them. | |
| **R** | **Research track, not promised:** foundation models, GNNs, federated learning, digital twins. Listed as intent, not as capability. | |

### 5.1 Scope honesty

The brief asked for 23 application domains and 19 methodological paradigms. A
package claiming all of them at once, with a thin shell behind each claim, is a
credibility liability rather than an achievement — reviewers in this field
check. The roadmap therefore builds **one domain to publishable depth (yield
prediction, done rigorously) before widening**. Suitability, disease, drought
and the rest reuse the same spine once it has been validated.

Nothing in this document is claimed to work until it has a test.

---

## 6. What this package is not

- Not a crop growth simulator — `apsimx` and `DSSAT` already bind APSIM and
  DSSAT properly.
- Not a new ML library — it registers existing ones.
- Not a GIS — `sf` and `terra` are the substrate.
- Not a replacement for `tidymodels` or `mlr3` — it is an agronomic front end
  that can hand off to either.

---

## References

- Roberts, D. R. et al. (2017) Cross-validation strategies for data with
  temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*
  **40**, 913–929. <doi:10.1111/ecog.02881>
- Meyer, H. & Pebesma, E. (2021) Predicting into unknown space? Estimating the
  area of applicability of spatial prediction models. *Methods in Ecology and
  Evolution* **12**, 1620–1633. <doi:10.1111/2041-210X.13650>
- McMaster, G. S. & Wilhelm, W. W. (1997) Growing degree-days: one equation,
  two interpretations. *Agricultural and Forest Meteorology* **87**, 291–300.
  <doi:10.1016/S0168-1923(97)00027-0>
- Lei, J., G'Sell, M., Rinaldo, A., Tibshirani, R. J. & Wasserman, L. (2018)
  Distribution-free predictive inference for regression. *Journal of the
  American Statistical Association* **113**, 1094–1111.
  <doi:10.1080/01621459.2017.1307116>

*All four DOIs were resolved against the Crossref API on 2026-08-04.*
