## Plots are checked for running cleanly on a null device and for returning the
## data they drew, so that the numbers behind a figure can be asserted even
## though the figure itself cannot.

plot_fixture <- function(n_units = 20, n_seasons = 3) {
    p <- agri_project(demo_agri_data(n_units = n_units, n_seasons = n_seasons))
    p <- add_soil(p, source = "demo_soil")
    build_features(phenology_windows(add_climate(p)), stats = "sum")
}

quietly_plot <- function(expr) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    force(expr)
}

test_that("projects and resampling schemes draw without error", {
    p <- plot_fixture()
    expect_silent(quietly_plot(plot(p)))
    rs <- resample_scheme(p, method = "spatial_block", k = 4)
    expect_silent(quietly_plot(plot(rs)))
    ## the scheme carries its own coordinates, so it plots on its own
    expect_equal(nrow(rs$coords), nrow(p$features))
})

test_that("a scheme without coordinates refuses to plot", {
    p <- plot_fixture()
    rs <- resample_scheme(p, method = "spatial_block", k = 3)
    rs$coords <- NULL
    expect_error(quietly_plot(plot(rs)), "no coordinates")
})

test_that("model plots run for every type", {
    p <- plot_fixture()
    m <- train_model(p, "yield", algorithm = "lm", k = 4)
    for (ty in c("observed", "residuals", "importance")) {
        expect_silent(quietly_plot(plot(m, type = ty)))
    }
    expect_error(quietly_plot(plot(m, type = "nonsense")), "should be one of")
})

test_that("plot_map returns the values it drew, one row per unit", {
    p <- plot_fixture()
    m <- train_model(p, "yield", algorithm = "lm", k = 4,
                     compare_random = FALSE)
    for (w in c("prediction", "residual", "uncertainty")) {
        d <- quietly_plot(plot_map(m, w))
        expect_true(all(c("unit_id", "value", "x", "y") %in% names(d)))
        expect_gt(nrow(d), 0)
        expect_false(anyNA(d$x))
        ## one season only, so a unit must not appear twice
        expect_false(anyDuplicated(d$unit_id) > 0)
    }
    expect_error(quietly_plot(plot_map(m, season = 1899)), "no observations")
    expect_error(plot_map(structure(list(), class = "nope")), "train_model")
})

test_that("the residual map is centred on zero and matches the residuals", {
    p <- plot_fixture()
    m <- train_model(p, "yield", algorithm = "lm", k = 4,
                     compare_random = FALSE)
    d <- quietly_plot(plot_map(m, "residual"))
    s1 <- m$keys$season_id[1L]
    expect_equal(d$value,
                 (m$y - m$oof)[m$keys$season_id == s1],
                 tolerance = 1e-10, ignore_attr = TRUE)
})

test_that("plot_effect draws each method and returns the effect", {
    p <- plot_fixture()
    m <- train_model(p, "yield", algorithm = "lm", k = 4,
                     compare_random = FALSE)
    a <- quietly_plot(plot_effect(m, "prcp_sum_grain_fill", "ale", grid = 8))
    expect_true(all(c("value", "effect") %in% names(a)))
    pd <- quietly_plot(plot_effect(m, "prcp_sum_grain_fill", "pdp", grid = 8))
    expect_equal(nrow(pd), 8)
    ic <- quietly_plot(plot_effect(m, "prcp_sum_grain_fill", "ice", grid = 5))
    expect_true("id" %in% names(ic))
    expect_error(quietly_plot(plot_effect(m, "not_a_feature")), "no feature")
})

test_that("plot_uncertainty reports coverage consistent with uncertainty()", {
    p <- plot_fixture(24, 3)
    m <- train_model(p, "yield", algorithm = "lm", k = 4,
                     compare_random = FALSE)
    d <- quietly_plot(plot_uncertainty(m, level = 0.9))
    expect_true(all(c("pred", "obs", "lower", "upper", "covered") %in%
                        names(d)))
    ## bounds are the conformal half-width either side of the prediction
    q <- AgriFusionR:::.conformal_q(m$residuals, 0.9)
    expect_equal(d$upper - d$pred, rep(q, nrow(d)), tolerance = 1e-10)
    expect_equal(d$covered, d$obs >= d$lower & d$obs <= d$upper)
    ## ordered by prediction, as the axis label claims
    expect_false(is.unsorted(d$pred))
    ## in-sample coverage of the calibration set should be near nominal
    expect_gt(mean(d$covered), 0.8)
})
