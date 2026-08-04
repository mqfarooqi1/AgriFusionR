## Fixtures are sized so that features stay well below half the row count;
## otherwise train_model's rank-deficiency guard fires and buries real warnings.
xai_model <- function(algorithm = "lm", n_units = 20, n_seasons = 3,
                      aggregation = "phenology") {
    p <- agri_project(demo_agri_data(n_units = n_units, n_seasons = n_seasons))
    p <- build_features(phenology_windows(add_climate(p)), stats = "sum",
                        aggregation = aggregation)
    train_model(p, "yield", algorithm = algorithm, k = 3,
                compare_random = FALSE)
}

test_that("accumulated local effects are centred and monotone in the grid", {
    m <- xai_model()
    a <- explain(m, "ale", features = "prcp_sum_grain_fill", grid = 8)
    expect_true(all(c("feature", "value", "effect") %in% names(a)))
    expect_true(all(is.finite(a$effect)))
    ## grid points ascend, and the effect is centred on zero by construction
    expect_false(is.unsorted(a$value))
    expect_equal(mean(a$effect), 0, tolerance = 1e-8)
})

test_that("ALE recovers the direction of a known monotone relationship", {
    ## in the demo, yield rises with grain-fill rainfall by construction, so a
    ## correct ALE must slope upwards over that feature
    skip_if_not_installed("ranger")
    m <- xai_model("ranger", n_units = 25, n_seasons = 4)
    a <- explain(m, "ale", features = "prcp_sum_grain_fill", grid = 10)
    expect_gt(stats::cor(a$value, a$effect), 0.5)
})

test_that("ICE returns one curve per retained observation", {
    ## kept below the 40-curve subsampling threshold, so that averaging the
    ## ICE curves must reproduce partial dependence exactly rather than
    ## approximately
    m <- xai_model(n_units = 12, n_seasons = 3, aggregation = "season")
    ice <- explain(m, "ice", features = "prcp_sum_season", grid = 5)
    expect_true(all(c("feature", "id", "value", "prediction") %in% names(ice)))
    expect_equal(nrow(ice), length(unique(ice$id)) * 5)
    expect_true(all(is.finite(ice$prediction)))
    ## averaging the ICE curves must reproduce partial dependence
    pd <- explain(m, "pdp", features = "prcp_sum_season", grid = 5)
    avg <- tapply(ice$prediction, ice$value, mean)
    expect_equal(as.numeric(avg), pd$prediction, tolerance = 1e-6)
})

test_that("partial dependence still works and is finite", {
    m <- xai_model()
    pd <- explain(m, "pdp", features = "prcp_sum_grain_fill", grid = 6)
    expect_equal(nrow(pd), 6)
    expect_true(all(is.finite(pd$prediction)))
})

test_that("SHAP values are produced for tree learners and refused otherwise", {
    skip_if_not_installed("treeshap")
    skip_if_not_installed("ranger")
    m <- xai_model("ranger")
    s <- explain(m, "shap", features = c("prcp_sum_grain_fill",
                                         "heat_day_sum_silking"))
    expect_true(all(c("row", "feature", "shap") %in% names(s)))
    expect_true(all(is.finite(s$shap)))
    expect_setequal(unique(s$feature),
                    c("prcp_sum_grain_fill", "heat_day_sum_silking"))

    lin <- xai_model("lm")
    expect_error(explain(lin, "shap"), "tree learners")
})

test_that("explain rejects an unknown method", {
    m <- xai_model()
    expect_error(explain(m, "telepathy"), "should be one of")
})
