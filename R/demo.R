## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

## A closed, fully deterministic demonstration system. The weather is generated
## from harmonics rather than a random number generator, so it is reproducible
## without touching the global RNG state, and the yield is built from the same
## weather the framework will later read back. Because the data-generating
## process is known, the tests can assert that the pipeline recovers it.

#' @keywords internal
#' @noRd
.unit_hash <- function(unit_id) {
    v <- utf8ToInt(unit_id)
    (sum(v * seq_along(v)) %% 1009L) / 1009
}

#' @keywords internal
#' @noRd
.synthetic_weather <- function(unit_id, lon, lat, dates) {
    h <- .unit_hash(unit_id)
    doy <- as.integer(format(dates, "%j"))
    yr <- as.integer(format(dates, "%Y"))
    ## year enters the phase so that seasons differ from one another
    hy <- h + (yr %% 17L) / 17
    hemi <- if (lat >= 0) 1 else -1

    ## Calibrated so that daily maxima cross the 30 C heat-stress threshold
    ## around flowering in some unit-seasons and not others. Without that
    ## spread the heat-stress covariate would be constant, and a constant
    ## covariate is dropped, leaving the demonstration with a driver that does
    ## no work.
    seasonal <- sin(2 * pi * (doy - 105) / 365.25)
    tmean <- 18.5 - 0.35 * (abs(lat) - 25) + 10 * hemi * seasonal +
        5 * sin(2 * pi * (doy / 29 + hy))
    trange <- 11 + 3 * cos(2 * pi * (doy / 23 + h))

    wet <- sin(2 * pi * (doy / 37 + hy)) +
        0.8 * sin(2 * pi * (doy / 11 + 3 * hy)) +
        0.6 * sin(2 * pi * (doy / 97 + 5 * h))

    data.frame(
        date = dates,
        tmax = round(tmean + trange / 2, 2),
        tmin = round(tmean - trange / 2, 2),
        prcp = round(pmax(0, 5.5 * (wet - 0.55)), 2),
        stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
.demo_clay <- function(lon, lat) {
    round(28 + 12 * sin(lon / 1.7) + 8 * cos(lat / 1.3), 1)
}

#' A demonstration agricultural data set
#'
#' Generates a multi-field, multi-season data set whose yields are produced by
#' a known process, for examples, tests and teaching.
#'
#' The data are **simulated, not observed**. Yield is built from rainfall
#' accumulated during grain fill, the count of days above 30 degrees during
#' silking, soil clay content, a smooth spatial trend and a season effect.
#' Because those drivers are known exactly, an analysis of this data set can be
#' checked against the truth rather than against a previous run.
#'
#' Generation is deterministic: no random number generator is used and the
#' global RNG state is not touched, so repeated calls return identical data.
#'
#' @param n_units Number of management units.
#' @param n_seasons Number of seasons per unit.
#' @param crop Crop name, used for thermal parameters.
#' @param start_year First season.
#' @return A data frame with one row per unit and season, containing
#'   coordinates, the growing window, soil clay, yield, and the true driver
#'   values used to build it.
#' @seealso [agri_project()], [add_climate()]
#' @examples
#' d <- demo_agri_data(n_units = 6, n_seasons = 2)
#' str(d)
#' @export
demo_agri_data <- function(n_units = 40, n_seasons = 4, crop = "maize",
                           start_year = 2018) {
    n_units <- max(2L, as.integer(n_units))
    n_seasons <- max(1L, as.integer(n_seasons))

    ## Units laid out over a northern-hemisphere maize belt. Maize is used
    ## because silking falls in midsummer, so heat stress at flowering is a
    ## live driver rather than a nominal one, and the whole season fits inside
    ## one calendar year.
    side <- ceiling(sqrt(n_units))
    grid <- expand.grid(ix = seq_len(side), iy = seq_len(side))[seq_len(n_units), ]
    lon <- -95 + 7 * (grid$ix - 1) / max(1, side - 1)
    lat <- 39 + 5 * (grid$iy - 1) / max(1, side - 1)
    unit_id <- sprintf("F%03d", seq_len(n_units))
    clay <- .demo_clay(lon, lat)

    par <- crop_parameters(crop)
    out <- list()

    for (s in seq_len(n_seasons)) {
        yr <- start_year + s - 1L
        for (i in seq_len(n_units)) {
            ## later sowing further north
            plant_doy <- round(120 + 1.6 * (lat[i] - 39))
            start <- as.Date(sprintf("%d-01-01", yr)) + plant_doy - 1L
            end <- start + 169L
            dates <- seq(start, end, by = "day")

            w <- .synthetic_weather(unit_id[i], lon[i], lat[i], dates)
            gdd <- growing_degree_days(w$tmin, w$tmax, par$t_base[1L],
                                       par$t_upper[1L])
            cum <- cumsum(gdd)
            idx <- findInterval(cum, c(0, par$gdd_end))
            idx[idx < 1L] <- 1L
            idx[idx > nrow(par)] <- nrow(par)
            stage <- par$stage[idx]

            gf_rain <- sum(w$prcp[stage == "grain_fill"])
            heat <- sum(w$tmax[stage == "silking"] > 30)

            ## the true model, in tonnes per hectare
            yield <- 9.0 +
                0.010 * gf_rain -
                0.120 * heat +
                0.020 * (clay[i] - 28) +
                0.55 * sin(lon[i] / 2.3) +
                0.10 * ((yr %% 5L) - 2) +
                0.50 * (.unit_hash(paste0(unit_id[i], yr)) - 0.5)

            out[[length(out) + 1L]] <- data.frame(
                unit_id = unit_id[i], lon = lon[i], lat = lat[i],
                season = yr, planting = start, harvest = end,
                crop = crop, clay = clay[i],
                yield = round(pmax(0.1, yield), 3),
                true_gf_rain = round(gf_rain, 1),
                true_heat_days = heat,
                stringsAsFactors = FALSE)
        }
    }
    d <- do.call(rbind, out)
    rownames(d) <- NULL
    d
}
