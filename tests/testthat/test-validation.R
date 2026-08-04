## Aggregate with a single statistic by default. The full default set produces
## more features than these small fixtures have rows, which makes linear fits
## rank deficient and the resulting comparisons meaningless.
make_ready <- function(n_units = 16, n_seasons = 3, stats = "sum", ...) {
    p <- agri_project(demo_agri_data(n_units = n_units, n_seasons = n_seasons))
    p <- add_climate(p, source = "demo")
    p <- add_soil(p, source = "demo_soil")
    p <- phenology_windows(p)
    build_features(p, stats = stats, ...)
}

test_that("spatial folds never share a unit between train and test", {
    p <- make_ready(16, 2)
    for (meth in c("spatial_block", "leave_location_out")) {
        rs <- resample_scheme(p, method = meth, k = 4)
        for (f in rs$folds) {
            tr <- unique(p$features$unit_id[f$train])
            te <- unique(p$features$unit_id[f$test])
            expect_length(intersect(tr, te), 0)
        }
    }
})

test_that("forward_season never trains on the future", {
    p <- make_ready(8, 4)
    rs <- resample_scheme(p, method = "forward_season")
    expect_equal(rs$k, 3)
    for (f in rs$folds) {
        expect_lt(max(as.integer(p$features$season_id[f$train])),
                  min(as.integer(p$features$season_id[f$test])))
    }
})

test_that("a buffer removes nearby training rows", {
    p <- make_ready(16, 1)
    plain <- resample_scheme(p, method = "spatial_block", k = 4)
    buff <- resample_scheme(p, method = "spatial_block", k = 4, buffer = 220)
    n_plain <- sum(vapply(plain$folds, function(f) length(f$train), 1L))
    n_buff <- sum(vapply(buff$folds, function(f) length(f$train), 1L))
    expect_lt(n_buff, n_plain)
})

test_that("random resampling warns", {
    p <- make_ready(10, 2)
    expect_warning(resample_scheme(p, method = "random", k = 3),
                   "overstate skill")
})

test_that("training runs, predicts, and reports both resampling schemes", {
    p <- make_ready(24, 3)
    m <- train_model(p, target = "yield", algorithm = "lm", k = 4)
    expect_s3_class(m, "agri_model")
    expect_length(m$oof, nrow(p$features))
    expect_true(is.finite(m$metrics[["rmse"]]))
    expect_false(is.null(m$metrics_random))

    pr <- predict(m, interval = TRUE)
    expect_true(all(c(".pred", ".pred_oof", ".lower", ".upper") %in% names(pr)))
    expect_true(all(pr$.lower <= pr$.pred & pr$.pred <= pr$.upper))
    expect_equal(nrow(pr), nrow(p$features))

    expect_error(train_model(p, target = "nope"), "no column")
})

test_that("random cross-validation is more optimistic than spatial", {
    ## The demo system contains a genuine spatial trend, so holding out whole
    ## blocks must be harder than holding out scattered rows. Aggregate with a
    ## single statistic to keep the feature count well below the sample size,
    ## or a rank-deficient fit would make the comparison meaningless.
    p <- make_ready(25, 4)
    set.seed(42)
    m <- train_model(p, target = "yield", algorithm = "lm", k = 5)
    expect_gt(m$metrics_random[["r2"]], m$metrics[["r2"]])
})

test_that("conformal intervals cover at about the nominal rate", {
    p <- make_ready(20, 4)
    m <- train_model(p, target = "yield", algorithm = "lm", k = 4,
                     compare_random = FALSE)
    u <- uncertainty(m, level = 0.9)
    expect_gt(u$half_width, 0)
    expect_gt(u$coverage, 0.75)
    expect_lte(u$coverage, 1)
    ## a wider target must not give a narrower interval
    expect_gte(uncertainty(m, level = 0.95)$half_width, u$half_width)
    expect_error(uncertainty(m, level = 1.5), "between 0 and 1")
})

test_that("the pipeline recovers the demo system's true drivers", {
    skip_if_not_installed("ranger")
    p <- make_ready(30, 4)
    set.seed(7)
    m <- train_model(p, target = "yield", algorithm = "ranger", k = 5,
                     compare_random = FALSE)
    imp <- explain(m, n_perm = 5)
    top <- utils::head(imp$feature, 6)
    ## yield was built from grain-fill rainfall and anthesis heat days
    expect_true(any(grepl("grain_fill|silking", top)))
    expect_gt(m$metrics[["r2"]], 0)
})

test_that("partial dependence and the model card are produced", {
    p <- make_ready(24, 3)
    m <- train_model(p, target = "yield", algorithm = "lm", k = 3)
    set.seed(3)
    pd <- explain(m, method = "pdp", features = "prcp_sum_grain_fill",
                  grid = 8)
    expect_equal(nrow(pd), 8)
    expect_true(all(is.finite(pd$prediction)))

    card <- report(m)
    expect_true(any(grepl("^# Model card", card)))
    expect_true(any(grepl("Provenance", card)))
    expect_true(any(grepl("Limitations", card)))

    f <- tempfile(fileext = ".md")
    report(m, file = f)
    expect_true(file.exists(f))
    unlink(f)
})
