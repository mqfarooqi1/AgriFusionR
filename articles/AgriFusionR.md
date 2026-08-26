# Getting started with AgriFusionR

``` r

library(AgriFusionR)
```

## The problem this package addresses

R is well supplied with agricultural machine learning. Every component
you might want already exists on CRAN: five packages for spatial
cross-validation, seven for climate ingestion, three for Earth
observation, and every learner worth having. What is missing is the
layer that joins them, and two defaults that layer ought to enforce.

**First, covariates should be aligned to the crop, not the calendar.**
“Rainfall in September” means different things to two fields sown six
weeks apart. “Rainfall during grain fill” means the same thing to both.

**Second, models on spatial data should be validated spatially.** Under
random k-fold cross-validation almost every test point has a
near-duplicate in the training set, so the estimate answers a question
nobody asked.

## The unit of analysis

Everything is keyed on a **management unit within a season**. A project
is built from one row per unit per season; column roles are detected
from common names.

``` r

d <- demo_agri_data(n_units = 30, n_seasons = 3)
head(d[, c("unit_id", "lon", "lat", "season", "planting", "harvest", "yield")])
#>   unit_id   lon lat season   planting    harvest yield
#> 1    F001 -95.0  39   2018 2018-04-30 2018-10-16 7.976
#> 2    F002 -93.6  39   2018 2018-04-30 2018-10-16 7.752
#> 3    F003 -92.2  39   2018 2018-04-30 2018-10-16 7.406
#> 4    F004 -90.8  39   2018 2018-04-30 2018-10-16 7.087
#> 5    F005 -89.4  39   2018 2018-04-30 2018-10-16 7.082
#> 6    F006 -88.0  39   2018 2018-04-30 2018-10-16 7.133

p <- agri_project(d)
p
#> <agri_project>
#>   observations : 90 
#>   units        : 30 (unit_id) 
#>   seasons      : 3 (season) 
#>   window       : 2018-04-30 to 2020-10-21 
#>   extent       : x [-95.000, -88.000]  y [39.000, 43.000] 
#>   layers       : none 
#>   windows      : not derived 
#>   features     : not built
```

The demonstration data are simulated from a process that is known
exactly, so the pipeline can be checked against the truth rather than
against a previous run.

## Attaching covariates

Sources come from a registry, so adding a provider needs no change to
the package. Here we use the built-in offline sources;
`source = "power"` fetches real daily weather from NASA POWER through
the **nasapower** package.

``` r

p <- add_climate(p, source = "demo")
p <- add_soil(p, source = "demo_soil")
list_sources()[, c("name", "kind", "network")]
#>        name   kind network
#> 1      demo series   FALSE
#> 2 demo_soil static   FALSE
#> 3     power series    TRUE
#> 4    chirps series    TRUE
#> 5    daymet series    TRUE
#> 6 worldclim static    TRUE
#> 7 soilgrids static    TRUE
#> 8 elevation static    TRUE
```

## Thermal time and phenological windows

Stages are derived from accumulated growing degree days rather than
dates.

``` r

growing_degree_days(tmin = c(8, 12, 16), tmax = c(22, 28, 34), t_base = 10)
#> [1]  6 10 15
crop_parameters("maize")
#>    crop t_base t_upper      stage gdd_end
#> 1 maize     10      30  emergence     100
#> 2 maize     10      30 vegetative     500
#> 3 maize     10      30    silking     900
#> 4 maize     10      30 grain_fill    1400
#> 5 maize     10      30   maturity    1700
```

Those thresholds are **indicative defaults, not calibrated constants**.
Thermal requirements vary with cultivar and region; supply your own
through the `stages` argument for anything you intend to publish.

``` r

p <- phenology_windows(p)
head(p$windows, 4)
#>   unit_id season_id      stage      start        end days  gdd_end
#> 1    F001      2018  emergence 2018-04-30 2018-05-14   15   96.135
#> 2    F001      2018 vegetative 2018-05-15 2018-06-20   37  486.725
#> 3    F001      2018    silking 2018-06-21 2018-07-21   31  887.670
#> 4    F001      2018 grain_fill 2018-07-22 2018-08-29   39 1394.915
```

## Building the design matrix

Daily layers are reduced to one row per unit and season, aggregated
within stage. Stress counters are derived first.

``` r

p <- build_features(p, stats = c("mean", "sum"))
grep("grain_fill|silking", names(p$features), value = TRUE)[1:6]
#> [1] "tmax_mean_grain_fill" "tmax_sum_grain_fill"  "tmin_mean_grain_fill"
#> [4] "tmin_sum_grain_fill"  "prcp_mean_grain_fill" "prcp_sum_grain_fill"
```

## Checking before modelling

The most valuable check is the leakage guard: a covariate window
reaching past the harvest it predicts produces a model that cannot be
deployed and a skill estimate that means nothing.

``` r

check_project(p)
#> check_project(): 12 issue(s), 0 of them errors.
#>   [note   ] outliers         feature 'tmax_mean_emergence' has 2 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmin_mean_emergence' has 2 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'prcp_mean_emergence' has 19 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'prcp_sum_emergence' has 19 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmax_mean_grain_fill' has 14 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmin_mean_grain_fill' has 9 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmax_sum_silking' has 5 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmin_mean_silking' has 5 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'tmax_mean_vegetative' has 6 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'dry_day_sum_emergence' has 4 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'dry_day_sum_maturity' has 2 value(s) beyond 3 MAD
#>   [note   ] outliers         feature 'heat_day_sum_silking' has 6 value(s) beyond 3 MAD
```

## Training

Spatial folds are the default. The same model is also scored with random
folds so the difference is a number rather than an argument.

``` r

set.seed(1)
m <- train_model(p, target = "yield", algorithm = "ranger", k = 5)
m
#> <agri_model>
#>   target     : yield 
#>   learner    : ranger 
#>   features   : 41 
#>   resampling : spatial_block (5 folds) 
#>   spatial CV : RMSE 0.577  MAE 0.499  R2 0.247  (n=90)
#>   random CV  : RMSE 0.296  MAE 0.248  R2 0.802
#>   optimism   : random CV overstates R2 by 0.555
```

## Uncertainty

Intervals are split conformal, which assumes nothing about the model or
the error distribution. Because the residuals come from spatial folds,
the intervals inherit that honesty.

``` r

uncertainty(m)
#> <agri_uncertainty>
#>   target        : yield 
#>   level         : 0.9 
#>   half-width    : 1.0109  (interval is prediction +/- this)
#>   calibration n : 90 
#>   coverage      : 0.922 estimated by split (target 0.90)
head(predict(m, interval = TRUE), 3)
#>   unit_id season_id    .pred .pred_oof   .lower   .upper
#> 1    F001      2018 7.787879   7.14278 6.776959 8.798800
#> 2    F001      2019 7.755924   7.10693 6.745003 8.766844
#> 3    F001      2020 7.458104   6.81329 6.447183 8.469024
```

## Does it hold on real data?

The claim above is easy to make on data you generated yourself.
`lasrosas.corn` in the **agridat** package is 3443 yield-monitor
observations from an Argentine maize field over two seasons —
measurements from someone else entirely, and the setting where spatial
autocorrelation bites hardest.

``` r

data(lasrosas.corn, package = "agridat")
d0 <- lasrosas.corn[seq(1, nrow(lasrosas.corn), by = 3), ]

real <- data.frame(unit_id = sprintf("p%05d", seq_len(nrow(d0))),
                   lon = d0$long, lat = d0$lat, season = d0$year,
                   yield = d0$yield)
covs <- data.frame(unit_id = real$unit_id, nitro = d0$nitro, bv = d0$bv)
for (lv in levels(d0$topo)) covs[[paste0("topo_", lv)]] <- +(d0$topo == lv)

register_source("lasrosas", function(units, seasons, ...) covs,
                provides = setdiff(names(covs), "unit_id"),
                kind = "static", requires_network = FALSE)

rp <- build_features(add_layer(agri_project(real), "lasrosas", "field"))
set.seed(11)
train_model(rp, target = "yield", algorithm = "ranger", k = 5)
#> <agri_model>
#>   target     : yield 
#>   learner    : ranger 
#>   features   : 6 
#>   resampling : spatial_block (5 folds) 
#>   spatial CV : RMSE 14.596  MAE 11.777  R2 0.459  (n=1148)
#>   random CV  : RMSE 12.514  MAE 10.199  R2 0.602
#>   optimism   : random CV overstates R2 by 0.143
```

On the full data set this reports an R² of 0.485 under spatial folds
against 0.624 under random folds: the usual way of reporting would have
overstated the model by 0.138. Conformal coverage on the same run is
0.901 against a nominal 0.90.

## Explaining

Importance is measured out of fold. Note that permutation importance is
unreliable when features are correlated, which climate features usually
are: shuffling one of a near-duplicate pair leaves the other carrying
the signal.

``` r

set.seed(2)
head(explain(m, n_perm = 3), 5)
#>                feature  importance          sd
#> 1 tmax_mean_grain_fill 0.006543514 0.006885661
#> 2   prcp_mean_maturity 0.005216716 0.007419240
#> 3    prcp_sum_maturity 0.004109502 0.003766809
#> 4   tmax_mean_maturity 0.003697708 0.002005467
#> 5  tmax_sum_grain_fill 0.003608867 0.002925377
```

## Reporting

[`report()`](https://mqfarooqi1.github.io/AgriFusionR/reference/report.md)
writes a model card whose limitations section is generated from the
model’s own diagnostics, so it cannot drift out of step with the
results.

``` r

cat(head(report(m), 24), sep = "\n")
#> # Model card
#> 
#> Generated 2026-08-26 by AgriFusionR.
#> 
#> ## What was fitted
#> 
#> - Target: `yield`
#> - Learner: `ranger`
#> - Observations: 90
#> - Features: 41
#> - Units: 30 over 3 season(s)
#> 
#> ## How it was validated
#> 
#> - Scheme: spatial_block, 5 folds
#> 
#> | Resampling | n | RMSE | MAE | R2 | Bias |
#> |---|---|---|---|---|---|
#> | spatial_block (reported) | 90 | 0.577 | 0.499 | 0.247 | -0.016 |
#> | random (for comparison) | 90 | 0.296 | 0.248 | 0.802 | -0.001 |
#> 
#> - Prediction interval at 90%: +/- 1.0109 (split conformal)
#> - Estimated coverage: 0.922
```

## Extending

A new provider or algorithm is a function and one registration call.

``` r

register_learner("median_only",
                 fit = function(x, y, ...) stats::median(y),
                 predict = function(object, newx, ...) rep(object, nrow(newx)),
                 description = "Baseline: predict the median")
tail(list_learners(), 2)
#>           name requires
#> 10       stack         
#> 11 median_only         
#>                                                                                description
#> 10 Stacked ensemble of the available base learners, weighted by non-negative least squares
#> 11                                                            Baseline: predict the median
```
