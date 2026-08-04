## Validation against real, independently published data.
##
## lasrosas.corn is 3443 yield-monitor observations from an Argentine maize
## field over two seasons (Lasrosas, Cordoba). Dense yield-monitor data is the
## setting where spatial autocorrelation is most severe, so it is the right
## place to check that the package's central claim survives contact with
## measurements nobody here generated.

skip_if_not_installed("agridat")
skip_if_not_installed("ranger")

real_project <- function(n = 1200) {
    e <- new.env()
    utils::data("lasrosas.corn", package = "agridat", envir = e)
    d0 <- e$lasrosas.corn
    i <- seq(1L, nrow(d0), length.out = min(n, nrow(d0)))
    d0 <- d0[unique(round(i)), , drop = FALSE]

    d <- data.frame(unit_id = sprintf("p%05d", seq_len(nrow(d0))),
                    lon = d0$long, lat = d0$lat, season = d0$year,
                    yield = d0$yield, stringsAsFactors = FALSE)
    covs <- data.frame(unit_id = d$unit_id, nitro = d0$nitro, bv = d0$bv,
                       stringsAsFactors = FALSE)
    for (lv in levels(d0$topo)) {
        covs[[paste0("topo_", lv)]] <- as.numeric(d0$topo == lv)
    }
    register_source("lasrosas_test", fetch = function(units, seasons, ...) covs,
                    provides = setdiff(names(covs), "unit_id"),
                    kind = "static", requires_network = FALSE)
    p <- agri_project(d)
    build_features(add_layer(p, source = "lasrosas_test", layer = "field"))
}

test_that("the project ingests real georeferenced yield data", {
    p <- real_project()
    expect_s3_class(p, "agri_project")
    expect_gt(nrow(p$features), 1000)
    expect_true(all(c("nitro", "bv") %in% names(p$features)))
    ## no harvest dates, so the leakage guard should say so rather than pass
    iss <- check_project(p)
    expect_equal(sum(iss$severity == "error"), 0)
    expect_true(any(iss$check == "leakage"))
})

test_that("random cross-validation flatters the model on real data too", {
    p <- real_project()
    set.seed(11)
    m <- train_model(p, target = "yield", algorithm = "ranger", k = 5)
    expect_gt(m$metrics[["r2"]], 0.2)
    ## the claim the package is built around, on data we did not generate
    expect_gt(m$metrics_random[["r2"]], m$metrics[["r2"]])
})

test_that("conformal coverage holds on a real error distribution", {
    p <- real_project()
    set.seed(11)
    m <- train_model(p, target = "yield", algorithm = "ranger", k = 5,
                     compare_random = FALSE)
    u <- uncertainty(m, level = 0.9)
    ## distribution-free, so coverage should sit close to nominal even though
    ## these residuals look nothing like the simulated ones
    expect_gt(u$coverage, 0.85)
    expect_lt(u$coverage, 0.95)
})
