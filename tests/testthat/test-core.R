test_that("growing degree days match hand computation", {
    ## (20+10)/2 - 5
    expect_equal(growing_degree_days(10, 20, t_base = 5), 10)
    ## both bounds lifted to the base: no development
    expect_equal(growing_degree_days(0, 2, t_base = 10), 0)
    ## upper cap bites: min(40,25)=25, min(20,25)=20 -> 22.5 - 10
    expect_equal(growing_degree_days(20, 40, t_base = 10, t_upper = 25), 12.5)
    ## never negative
    expect_true(all(growing_degree_days(c(-10, -5), c(-2, 0), t_base = 5) == 0))
    expect_error(growing_degree_days(1:3, 1:2), "same length")
})

test_that("crop parameters are ordered and complete", {
    p <- crop_parameters("wheat")
    expect_true(all(diff(p$gdd_end) > 0))
    expect_true(all(c("anthesis", "grain_fill") %in% p$stage))
    expect_error(crop_parameters("unobtainium"), "no parameters for crop")
})

test_that("demo data is deterministic and self-consistent", {
    a <- demo_agri_data(n_units = 5, n_seasons = 2)
    b <- demo_agri_data(n_units = 5, n_seasons = 2)
    expect_identical(a, b)
    expect_equal(nrow(a), 10)
    expect_true(all(a$harvest > a$planting))
    expect_true(all(a$yield > 0))
})

test_that("project construction detects roles and rejects duplicate keys", {
    d <- demo_agri_data(n_units = 4, n_seasons = 2)
    p <- agri_project(d)
    expect_s3_class(p, "agri_project")
    expect_equal(p$roles$unit_id, "unit_id")
    expect_equal(p$roles$x, "lon")
    expect_equal(p$roles$y, "lat")
    expect_equal(nrow(units_of(p)), 4)
    expect_equal(nrow(seasons_of(p)), 8)

    expect_error(agri_project(rbind(d, d[1, ])), "not unique")
    expect_error(agri_project(d[, c("yield"), drop = FALSE]),
                 "could not identify")
})

test_that("registries accept and expose new entries", {
    register_source("unit_test_src",
                    fetch = function(units, seasons, ...) {
                        data.frame(unit_id = units$unit_id, dummy = 1.5)
                    },
                    provides = "dummy", kind = "static",
                    requires_network = FALSE)
    expect_true("unit_test_src" %in% list_sources()$name)

    register_learner("unit_test_lrn",
                     fit = function(x, y, ...) mean(y),
                     predict = function(object, newx, ...) {
                         rep(object, nrow(newx))
                     })
    expect_true("unit_test_lrn" %in% list_learners()$name)
    expect_error(AgriFusionR:::.get_learner("nope"), "unknown learner")
    expect_error(AgriFusionR:::.get_source("nope"), "unknown source")
})
