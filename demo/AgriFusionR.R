## ---------------------------------------------------------------------------
## AgriFusionR: a guided tour of everything the package does
##
##   demo("AgriFusionR", package = "AgriFusionR")
##
## or just source this file. It runs offline from end to end in a couple of
## minutes and needs no data of your own. The last two sections need extra
## packages or the internet and skip themselves politely when either is absent.
##
## The commentary matters as much as the code: several steps exist to stop you
## making a mistake rather than to compute something, and those are the ones
## worth understanding.
## ---------------------------------------------------------------------------

library(AgriFusionR)

hr <- function(n, title) {
    cat("\n", strrep("=", 74), "\n", sprintf("%2d. %s", n, title), "\n",
        strrep("=", 74), "\n", sep = "")
}

## ---------------------------------------------------------------------------
hr(1, "What is registered")
## Sources and learners live in registries, so the package can be extended
## without being modified. Section 9 adds one of each.
## ---------------------------------------------------------------------------

print(list_sources()[, c("name", "kind", "network")])
cat("\n")
print(list_learners()[, c("name", "requires")])

cat("\nLearners needing a package you do not have simply cannot be selected;",
    "\nnothing else breaks. AgriFusionR itself imports only base packages.\n")

## ---------------------------------------------------------------------------
hr(2, "A project: management units observed over seasons")
## The unit of analysis is one management unit in one season. Every covariate
## added later has to reduce to that key, which is what keeps the pipeline
## composable.
## ---------------------------------------------------------------------------

field <- demo_agri_data(n_units = 30, n_seasons = 4)
cat("Raw data, one row per unit and season:\n")
print(utils::head(field[, c("unit_id", "lon", "lat", "season", "planting",
                            "harvest", "crop", "yield")], 3))

## column roles are detected from common names; override any of them by hand
p <- agri_project(field)
print(p)

cat("\nDetected roles: ")
cat(paste(names(unlist(p$roles)), unlist(p$roles), sep = "="), sep = ", ")
cat("\n\nThe key must be unique. A repeated unit-season is refused outright:\n")
bad <- try(agri_project(rbind(field, field[1, ])), silent = TRUE)
cat("  ", conditionMessage(attr(bad, "condition")), "\n")

## ---------------------------------------------------------------------------
hr(3, "Accessors and the provenance ledger")
## Every operation appends to a ledger. report() turns it into a methods
## section, which is what makes a re-run months later mean something.
## ---------------------------------------------------------------------------

cat("units_of():\n");   print(utils::head(units_of(p), 3))
cat("\nseasons_of():\n"); print(utils::head(seasons_of(p), 3))
cat("\nprovenance() so far:\n"); print(provenance(p)[, c("step", "detail")])

## ---------------------------------------------------------------------------
hr(4, "Attaching covariates")
## add_climate(), add_soil() and add_satellite() all go through the same source
## registry. Here the offline demo sources are used so this runs anywhere.
## ---------------------------------------------------------------------------

p <- add_climate(p, source = "demo")       # daily series, per unit and season
p <- add_soil(p, source = "demo_soil")     # static, one row per unit

cat("Climate layer (series):\n")
print(utils::head(p$layers$climate$data, 3))
cat("\nSoil layer (static):\n")
print(utils::head(p$layers$soil$data, 3))
cat("\nA layer already present is not refetched:\n")
p <- add_climate(p, source = "demo")

## ---------------------------------------------------------------------------
hr(5, "Thermal time")
## Growing degree days by the capped-average method. The two common readings of
## the same equation can differ by hundreds of degree days over a season, so
## the method is stated rather than assumed (McMaster & Wilhelm 1997).
## ---------------------------------------------------------------------------

cat("GDD for three days, base 10 C:\n")
print(growing_degree_days(tmin = c(8, 12, 16), tmax = c(22, 28, 34),
                          t_base = 10))
cat("\nSame days, capped at 30 C: heat above the cap stops counting:\n")
print(growing_degree_days(tmin = c(8, 12, 16), tmax = c(22, 28, 34),
                          t_base = 10, t_upper = 30))

cat("\nShipped thermal parameters for maize:\n")
print(crop_parameters("maize"))
cat("\nAvailable crops:", paste(unique(crop_parameters()$crop),
                                collapse = ", "), "\n")
cat("These are indicative defaults, NOT calibrated constants. A stage boundary\n",
    "wrong by a fortnight misattributes the weather the model sees. Supply your\n",
    "own through the `stages` argument for anything you intend to publish.\n",
    sep = "")

## ---------------------------------------------------------------------------
hr(6, "Phenological windows")
## Each day is labelled with the stage the crop had reached by then. This is
## the point of the package: "rainfall in September" means different things to
## two fields sown six weeks apart, "rainfall during grain fill" does not.
## ---------------------------------------------------------------------------

p <- phenology_windows(p)                  # crop taken from the data
cat("Windows for the first unit-season:\n")
w <- p$windows
print(w[w$unit_id == w$unit_id[1] & w$season_id == w$season_id[1], ])

cat("\nMean days per stage across the whole data set:\n")
cl <- p$layers$climate$data
print(round(table(cl$stage) /
            length(unique(paste(cl$unit_id, cl$season_id))), 1))

## ---------------------------------------------------------------------------
hr(7, "Building the design matrix")
## Daily layers collapse to one row per unit and season. Compare the three
## aggregations: phenological, calendar month, and whole season.
## ---------------------------------------------------------------------------

p <- build_features(p, stats = c("mean", "sum"))
cat("Phenological aggregation:", ncol(p$features) - 2, "features,",
    nrow(p$features), "rows\n")
cat("  e.g. ", paste(grep("grain_fill|silking", names(p$features),
                          value = TRUE)[1:4], collapse = ", "), "\n")

for (agg in c("monthly", "season")) {
    q <- build_features(p, aggregation = agg, stats = c("mean", "sum"))
    cat(sprintf("%-10s aggregation: %d features\n", agg,
                ncol(q$features) - 2))
}
cat("\nStress counters are derived before aggregating: days above the heat\n",
    "threshold, days below freezing, dry days, and the longest dry spell.\n",
    sep = "")
print(utils::head(p$features[, c("unit_id", "season_id",
                                 "heat_day_sum_silking",
                                 "prcp_sum_grain_fill", "max_dry_spell")], 3))

## ---------------------------------------------------------------------------
hr(8, "Checking before modelling")
## The leakage guard is the one that earns its keep: a covariate window
## reaching past the harvest it predicts gives a model that cannot be deployed
## and a skill estimate that means nothing.
## ---------------------------------------------------------------------------

cat("A healthy project:\n")
print(check_project(p))

cat("\nNow deliberately push one weather record past its harvest date:\n")
broken <- p
broken$layers$climate$data$date[1] <-
    broken$layers$climate$data$date[1] + 400L
iss <- check_project(broken)
print(iss[iss$check == "leakage", ])

## ---------------------------------------------------------------------------
hr(9, "Extending the package")
## A new data provider or algorithm is a function plus one registration call.
## No fork, no pull request, no redesign.
## ---------------------------------------------------------------------------

register_source(
    "demo_management",
    fetch = function(units, seasons, ...) {
        data.frame(unit_id = units$unit_id,
                   n_rate = 80 + 60 * (seq_len(nrow(units)) %% 4),
                   stringsAsFactors = FALSE)
    },
    provides = "n_rate", kind = "static", requires_network = FALSE,
    description = "Nitrogen rate per unit, for the demonstration")

register_learner(
    "always_median",
    fit = function(x, y, ...) stats::median(y),
    predict = function(object, newx, ...) rep(object, nrow(newx)),
    description = "Baseline: predict the median regardless of inputs")

cat("Registered and immediately usable:\n")
ls_s <- list_sources(); ls_l <- list_learners()
print(ls_s[ls_s$name == "demo_management", c("name", "kind", "provides")])
print(ls_l[ls_l$name == "always_median", c("name", "description")])

p <- add_layer(p, source = "demo_management", layer = "management")
p <- build_features(p, stats = c("mean", "sum"))
cat("\nn_rate now joins the design matrix:",
    "n_rate" %in% names(p$features), "\n")

## ---------------------------------------------------------------------------
hr(10, "Resampling: the decision that matters most")
## Neighbouring fields share weather, soil and management. Under random folds a
## test point nearly always has a near-duplicate in training, so the estimate
## answers a question nobody asked. Spatial blocking is the default.
## ---------------------------------------------------------------------------

for (meth in c("spatial_block", "leave_location_out", "forward_season")) {
    rs <- resample_scheme(p, method = meth, k = 5)
    shared <- vapply(rs$folds, function(f) {
        length(intersect(unique(p$features$unit_id[f$train]),
                         unique(p$features$unit_id[f$test])))
    }, 1L)
    cat(sprintf("%-20s %d folds, units shared between train and test: %d\n",
                meth, rs$k, sum(shared)))
}
cat("\nBuffering drops training rows near any test unit, removing the\n",
    "optimism that blocking alone leaves at block edges:\n", sep = "")
for (b in c(0, 150, 300)) {
    rs <- resample_scheme(p, method = "spatial_block", k = 5, buffer = b)
    cat(sprintf("  buffer %3d km -> %d training rows in total\n", b,
                sum(vapply(rs$folds, function(f) length(f$train), 1L))))
}
cat("\nAsking for random folds warns, on purpose:\n")
invisible(tryCatch(resample_scheme(p, method = "random", k = 5),
                   warning = function(w) cat("  ", conditionMessage(w), "\n")))

## ---------------------------------------------------------------------------
hr(11, "Training, and the size of the lie random folds tell")
## train_model() scores the same model both ways and reports the difference.
## ---------------------------------------------------------------------------

set.seed(1)
algo <- if (requireNamespace("ranger", quietly = TRUE)) "ranger" else "lm"
m <- train_model(p, target = "yield", algorithm = algo, k = 5)
print(m)

cat("\nThat gap is the amount by which the usual way of reporting would have\n",
    "overstated this model. It is not an artefact of the demonstration; it is\n",
    "what spatial autocorrelation does to a random split.\n", sep = "")

## ---------------------------------------------------------------------------
hr(12, "Comparing learners under the same honest scheme")
## ---------------------------------------------------------------------------

cand <- c("lm", "glm", "knn", "always_median",
          if (requireNamespace("ranger", quietly = TRUE)) "ranger",
          if (requireNamespace("xgboost", quietly = TRUE)) "xgboost",
          if (requireNamespace("Cubist", quietly = TRUE)) "cubist",
          if (requireNamespace("glmnet", quietly = TRUE)) "enet",
          if (requireNamespace("kernlab", quietly = TRUE)) "svm")
res <- do.call(rbind, lapply(cand, function(a) {
    set.seed(1)
    mm <- train_model(p, "yield", algorithm = a, k = 5,
                      compare_random = FALSE)
    data.frame(learner = a, rmse = round(mm$metrics[["rmse"]], 3),
               r2 = round(mm$metrics[["r2"]], 3))
}))
print(res[order(res$rmse), ], row.names = FALSE)
cat("\n`always_median` is there as a floor: any learner that cannot beat it\n",
    "has found nothing. Note how modest the gaps between real learners are\n",
    "once the validation is honest.\n", sep = "")

if (requireNamespace("ranger", quietly = TRUE) &&
    requireNamespace("glmnet", quietly = TRUE)) {
    set.seed(2)
    ms <- train_model(p, "yield", algorithm = "stack", k = 5,
                      compare_random = FALSE)
    cat("\nStacked ensemble weights, by non-negative least squares:\n")
    print(round(stack_weights(ms), 3))
    cat("A stack putting all its weight on one learner is telling you the\n",
        "others added nothing.\n", sep = "")
}

## ---------------------------------------------------------------------------
hr(13, "Prediction and distribution-free intervals")
## Split conformal: assumes nothing about the model or the error distribution,
## and inherits the honesty of the spatial residuals it is calibrated on.
## ---------------------------------------------------------------------------

pr <- predict(m, interval = TRUE, level = 0.9)
cat(".pred is from the final model, .pred_oof is the out-of-fold prediction,\n",
    "which is the honest one:\n", sep = "")
print(utils::head(pr, 4))

u <- uncertainty(m, level = 0.9)
print(u)
cat("\nCoverage is estimated by splitting the residuals, calibrating on one\n",
    "half and measuring on the other, because a half-width and a coverage\n",
    "check taken from the same residuals would be circular.\n", sep = "")

cat("\nWider targets give wider intervals, as they must:\n")
for (lv in c(0.5, 0.8, 0.9, 0.95)) {
    cat(sprintf("  %.0f%%: +/- %.3f\n", 100 * lv,
                uncertainty(m, level = lv)$half_width))
}

## ---------------------------------------------------------------------------
hr(14, "Explaining the model")
## Five methods, each answering a different question.
## ---------------------------------------------------------------------------

set.seed(3)
cat("Out-of-fold permutation importance, top 6:\n")
print(utils::head(explain(m, "importance", n_perm = 3), 6), row.names = FALSE)
cat("
Permutation importance is unreliable when features are correlated,
",
    "which climate features are: shuffling one of a near-duplicate pair
",
    "leaves the other carrying the signal, so both look unimportant. Read
",
    "the ranking as indicative, alongside the effect curves below.
",
    sep = "")

top <- utils::head(explain(m, "importance", n_perm = 3)$feature, 1)
cat("\nAccumulated local effects for", top, ":\n")
print(utils::head(explain(m, "ale", features = top, grid = 8), 4))
cat("\nALE is preferred to partial dependence whenever predictors are\n",
    "correlated, which for weather features they always are: it never asks\n",
    "the model about combinations that do not occur.\n", sep = "")

cat("\nPartial dependence, same feature:\n")
print(utils::head(explain(m, "pdp", features = top, grid = 8), 3))
cat("\nICE, one curve per observation:\n")
print(utils::head(explain(m, "ice", features = top, grid = 5), 3))

if (requireNamespace("treeshap", quietly = TRUE) && m$learner == "ranger") {
    cat("\nExact tree SHAP:\n")
    print(utils::head(explain(m, "shap", features = top), 3))
} else {
    cat("\n[skipping SHAP: needs the treeshap package and a tree learner]\n")
}

## ---------------------------------------------------------------------------
hr(15, "Plots")
## Base graphics, so this needs no extra package. Written to a PNG so the demo
## works when run non-interactively.
## ---------------------------------------------------------------------------

png_file <- file.path(tempdir(), "agrifusionr-demo.png")
grDevices::png(png_file, width = 1500, height = 1000, res = 110)
op <- graphics::par(mfrow = c(2, 3), mar = c(4.5, 4.5, 3.5, 2))
plot(p)                                     # units in space
plot(resample_scheme(p, method = "spatial_block", k = 5))
plot(m, type = "observed")
plot(m, type = "residuals")
plot_map(m, "residual")
plot_uncertainty(m)
graphics::par(op)
grDevices::dev.off()
cat("Six panels written to:\n  ", png_file, "\n", sep = "")
cat("\nThe resampling plot is the one worth reading: it shows whether the\n",
    "blocking actually blocked anything, rather than leaving you to assume it.\n",
    sep = "")

## ---------------------------------------------------------------------------
hr(16, "The model card")
## The limitations section is generated from the model's own diagnostics, so it
## cannot drift out of step with the results.
## ---------------------------------------------------------------------------

card <- report(m)
cat(paste(utils::head(card, 26), collapse = "\n"), "\n...\n")
cat("\nLimitations it wrote about itself:\n")
i <- which(card == "## Limitations")
cat(paste(card[(i + 2):(i + 5)], collapse = "\n"), "\n")

## ---------------------------------------------------------------------------
hr(17, "The same pipeline on real, published data")
## agridat::lasrosas.corn is 3443 yield-monitor observations from an Argentine
## maize field over two seasons. Measurements nobody here generated.
## ---------------------------------------------------------------------------

if (requireNamespace("agridat", quietly = TRUE) &&
    requireNamespace("ranger", quietly = TRUE)) {
    e <- new.env()
    utils::data("lasrosas.corn", package = "agridat", envir = e)
    d0 <- e$lasrosas.corn[seq(1, nrow(e$lasrosas.corn), by = 2), ]

    real <- data.frame(unit_id = sprintf("p%05d", seq_len(nrow(d0))),
                       lon = d0$long, lat = d0$lat, season = d0$year,
                       yield = d0$yield, stringsAsFactors = FALSE)
    covs <- data.frame(unit_id = real$unit_id, nitro = d0$nitro, bv = d0$bv,
                       stringsAsFactors = FALSE)
    for (lv in levels(d0$topo)) covs[[paste0("topo_", lv)]] <- +(d0$topo == lv)
    register_source("lasrosas_demo",
                    function(units, seasons, ...) covs,
                    provides = setdiff(names(covs), "unit_id"),
                    kind = "static", requires_network = FALSE)

    rp <- build_features(add_layer(agri_project(real), "lasrosas_demo",
                                   "field"))
    set.seed(11)
    rm_ <- train_model(rp, "yield", algorithm = "ranger", k = 5)
    print(rm_)
    cat("\nThe gap survives contact with data we did not make up.\n")
} else {
    cat("[skipping: needs the agridat and ranger packages]\n")
}

## ---------------------------------------------------------------------------
hr(18, "Live data")
## Off by default so the demo never depends on the network. Set the flag to
## fetch real daily weather from NASA POWER.
## ---------------------------------------------------------------------------

fetch_live <- FALSE
if (fetch_live && requireNamespace("nasapower", quietly = TRUE)) {
    site <- data.frame(unit_id = "canberra", lon = 149.13, lat = -35.28,
                       season = 2023,
                       planting = as.Date("2023-05-01"),
                       harvest = as.Date("2023-05-20"), yield = 5)
    lp <- add_climate(agri_project(site), source = "power")
    print(utils::head(lp$layers$climate$data, 3))
} else {
    cat("[not fetching: set fetch_live <- TRUE, needs nasapower and internet]\n")
    cat("Other remote sources: chirps, daymet, worldclim, soilgrids,",
        "elevation.\n")
}

hr(19, "Done")
cat("Covered: registries, the project object, provenance, covariate layers,\n",
    "thermal time, phenological windows, feature building, quality and\n",
    "leakage checks, four resampling schemes, ten learners, stacking,\n",
    "conformal intervals, five explanation methods, plots, model cards,\n",
    "extension, and real data.\n\n", sep = "")
cat("Documentation: https://mqfarooqi1.github.io/AgriFusionR/\n")
cat("Citation:      citation(\"AgriFusionR\")\n")
