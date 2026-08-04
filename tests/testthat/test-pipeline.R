make_project <- function(n_units = 12, n_seasons = 3) {
    p <- agri_project(demo_agri_data(n_units = n_units, n_seasons = n_seasons))
    p <- add_climate(p, source = "demo")
    phenology_windows(p)
}

test_that("climate layer covers exactly each growing window", {
    p <- agri_project(demo_agri_data(n_units = 3, n_seasons = 2))
    p <- add_climate(p, source = "demo")
    cl <- p$layers$climate$data
    s <- seasons_of(p)
    expect_true(all(c("unit_id", "season_id", "date", "tmin", "tmax", "prcp")
                    %in% names(cl)))
    for (i in seq_len(nrow(s))) {
        d <- cl$date[cl$unit_id == s$unit_id[i] &
                         cl$season_id == s$season_id[i]]
        expect_equal(min(d), s$start[i])
        expect_equal(max(d), s$end[i])
    }
    ## a second call does not refetch
    expect_message(add_climate(p, source = "demo"), "already present")
})

test_that("phenological stages accumulate in order", {
    p <- make_project(4, 2)
    cl <- p$layers$climate$data
    expect_true("stage" %in% names(cl))

    ## within a unit-season, cumulative GDD is non-decreasing and the stage
    ## index never goes backwards
    key <- paste(cl$unit_id, cl$season_id)
    for (k in unique(key)) {
        i <- which(key == k)
        i <- i[order(cl$date[i])]
        expect_true(all(diff(cl$gdd_cum[i]) >= 0))
        expect_true(all(diff(as.integer(cl$stage[i])) >= 0))
    }
    ## windows do not overlap within a unit-season
    w <- p$windows
    wk <- paste(w$unit_id, w$season_id)
    for (k in unique(wk)) {
        ww <- w[wk == k, ]
        ww <- ww[order(ww$start), ]
        if (nrow(ww) > 1L) {
            expect_true(all(ww$start[-1] > ww$end[-nrow(ww)]))
        }
    }
})

test_that("features reduce to one row per unit-season with stage names", {
    p <- build_features(make_project(6, 2))
    f <- p$features
    expect_equal(nrow(f), 12)
    expect_false(anyDuplicated(paste(f$unit_id, f$season_id)) > 0)
    expect_true(any(grepl("^prcp_sum_grain_fill$", names(f))))
    expect_true(any(grepl("^heat_day_sum_silking$", names(f))))
    expect_true("max_dry_spell" %in% names(f))

    ## aggregation actually aggregates: season-level sum equals the raw sum
    ps <- build_features(make_project(3, 1), aggregation = "season",
                         stats = "sum")
    cl <- ps$layers$climate$data
    tot <- tapply(cl$prcp, paste(cl$unit_id, cl$season_id), sum)
    got <- ps$features$prcp_sum_season
    names(got) <- paste(ps$features$unit_id, ps$features$season_id)
    expect_equal(as.numeric(got[names(tot)]), as.numeric(tot), tolerance = 1e-8)
})

test_that("phenology aggregation is refused without stages", {
    p <- agri_project(demo_agri_data(n_units = 3, n_seasons = 1))
    p <- add_climate(p, source = "demo")
    expect_error(build_features(p), "no phenological stages")
    expect_silent(build_features(p, aggregation = "season"))
})

test_that("the leakage guard fires on post-harvest covariates", {
    p <- make_project(4, 2)
    expect_equal(sum(check_project(p)$severity == "error"), 0)

    ## push one layer row past its harvest date
    bad <- p
    bad$layers$climate$data$date[1] <-
        bad$layers$climate$data$date[1] + 400L
    iss <- check_project(bad)
    expect_true(any(iss$check == "leakage" & iss$severity == "error"))
})

test_that("static layers join by unit", {
    p <- make_project(5, 2)
    p <- add_soil(p, source = "demo_soil")
    p <- build_features(p)
    expect_true(all(c("clay", "sand") %in% names(p$features)))
    ## clay is a property of the unit, so it repeats across that unit's seasons
    byu <- tapply(p$features$clay, p$features$unit_id,
                  function(v) length(unique(v)))
    expect_true(all(byu == 1))
})
