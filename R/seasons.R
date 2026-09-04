#' Growing degree days
#'
#' Daily thermal time by the capped-average method: the mean of the daily
#' maximum and minimum, each first constrained to the interval between the base
#' and upper temperatures, less the base temperature, with negative values set
#' to zero.
#'
#' This is the interpretation McMaster and Wilhelm (1997) label Method 1 with a
#' horizontal cut-off. The choice matters: the two common interpretations of the
#' same equation can differ by hundreds of degree days over a season, so the
#' method is stated rather than left implicit.
#'
#' @param tmin,tmax Numeric vectors of daily minimum and maximum temperature in
#'   degrees Celsius.
#' @param t_base Base temperature below which development is taken to stop.
#' @param t_upper Temperature above which further warmth adds no development.
#' @return A numeric vector of daily growing degree days, never negative.
#' @references McMaster, G. S. & Wilhelm, W. W. (1997) "Growing degree-days:
#'   one equation, two interpretations." Agricultural and Forest Meteorology
#'   87, 291-300. \doi{10.1016/S0168-1923(97)00027-0}
#' @seealso [crop_parameters()], [phenology_windows()]
#' @examples
#' growing_degree_days(tmin = c(4, 8, 12), tmax = c(18, 24, 33), t_base = 5)
#' @export
growing_degree_days <- function(tmin, tmax, t_base = 5, t_upper = Inf) {
    if (length(tmin) != length(tmax)) {
        stop("`tmin` and `tmax` must be the same length.", call. = FALSE)
    }
    if (any(tmax < tmin, na.rm = TRUE)) {
        warning("`tmax` is below `tmin` somewhere; check the inputs.",
                call. = FALSE)
    }
    hi <- pmax(pmin(tmax, t_upper), t_base)
    lo <- pmax(pmin(tmin, t_upper), t_base)
    pmax((hi + lo) / 2 - t_base, 0)
}

#' Indicative crop thermal parameters
#'
#' Base and upper temperatures, and cumulative growing degree days at the end
#' of each phenological stage, for a small set of crops.
#'
#' @section Calibrate before trusting:
#' These values are **indicative defaults for getting started, not calibrated
#' constants**. Thermal requirements vary substantially with cultivar,
#' photoperiod and region, and a stage boundary that is wrong by a fortnight
#' will misattribute the weather a model sees. Supply your own thresholds
#' through the `stages` argument of [phenology_windows()] for any analysis you
#' intend to publish.
#'
#' @param crop Optional crop name. When `NULL`, all crops are returned.
#' @return A data frame with columns `crop`, `t_base`, `t_upper`, `stage` and
#'   `gdd_end`, ordered by crop and cumulative thermal time.
#' @seealso [growing_degree_days()], [phenology_windows()]
#' @examples
#' crop_parameters("wheat")
#' unique(crop_parameters()$crop)
#' @export
crop_parameters <- function(crop = NULL) {
    mk <- function(crop, t_base, t_upper, stage, gdd_end) {
        data.frame(crop = crop, t_base = t_base, t_upper = t_upper,
                   stage = stage, gdd_end = gdd_end, stringsAsFactors = FALSE)
    }
    tab <- rbind(
        mk("wheat", 0, 30,
           c("emergence", "tillering", "stem_elongation", "anthesis",
             "grain_fill", "maturity"),
           c(150, 500, 900, 1300, 1900, 2200)),
        mk("maize", 10, 30,
           c("emergence", "vegetative", "silking", "grain_fill", "maturity"),
           c(100, 500, 900, 1400, 1700)),
        mk("rice", 10, 32,
           c("emergence", "tillering", "panicle", "flowering", "maturity"),
           c(120, 500, 900, 1200, 1800)),
        mk("soybean", 10, 30,
           c("emergence", "vegetative", "flowering", "pod_fill", "maturity"),
           c(90, 450, 800, 1200, 1600)),
        mk("canola", 5, 27,
           c("emergence", "rosette", "flowering", "pod_fill", "maturity"),
           c(130, 450, 900, 1300, 1700)),
        mk("generic", 5, 30,
           c("early", "mid", "late", "maturity"),
           c(300, 800, 1400, 1800)))
    if (is.null(crop)) return(tab)
    out <- tab[tab$crop == tolower(crop), , drop = FALSE]
    if (!nrow(out)) {
        stop("no parameters for crop '", crop, "'. Available: ",
             paste(unique(tab$crop), collapse = ", "),
             ". Supply your own via the `stages` argument.", call. = FALSE)
    }
    rownames(out) <- NULL
    out
}

#' Derive phenological windows from accumulated thermal time
#'
#' Labels every day of every growing season with the phenological stage the
#' crop had reached by that date, based on accumulated growing degree days, and
#' summarises the resulting windows.
#'
#' Aligning covariates to phenology rather than to the calendar is the point of
#' the exercise. "Rainfall in September" means different things to two crops
#' sown six weeks apart; "rainfall during grain fill" means the same thing to
#' both. Aggregation in [build_features()] uses these labels.
#'
#' @param p An [agri_project()] with a climate layer providing `tmin` and `tmax`.
#' @param crop Crop name used to look up thermal parameters. When `NULL`, the
#'   project's crop column is used if present, otherwise `"generic"`.
#' @param stages Optional data frame of custom thresholds with columns `stage`
#'   and `gdd_end`, overriding [crop_parameters()].
#' @param t_base,t_upper Optional overrides for the base and upper
#'   temperatures.
#' @param layer Name of the climate layer to read.
#' @return The project, with daily stage labels attached to the climate layer
#'   and a window summary available as `p$windows`.
#' @seealso [growing_degree_days()], [crop_parameters()], [build_features()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
#' p <- add_climate(p, source = "demo")
#' p <- phenology_windows(p)
#' head(p$windows)
#' @export
phenology_windows <- function(p, crop = NULL, stages = NULL,
                              t_base = NULL, t_upper = NULL,
                              layer = "climate") {
    cl <- p$layers[[layer]]
    if (is.null(cl)) {
        stop("no layer called '", layer, "'; call add_climate() first.",
             call. = FALSE)
    }
    if (!all(c("tmin", "tmax") %in% names(cl$data))) {
        stop("layer '", layer, "' must provide 'tmin' and 'tmax'.",
             call. = FALSE)
    }
    if (is.null(crop)) {
        crop <- if (!is.null(p$roles$crop)) {
            as.character(p$obs[[p$roles$crop]][1L])
        } else "generic"
    }
    par <- if (is.null(stages)) crop_parameters(crop) else NULL
    tb <- t_base %||% (if (!is.null(par)) par$t_base[1L] else 5)
    tu <- t_upper %||% (if (!is.null(par)) par$t_upper[1L] else Inf)
    st <- if (is.null(stages)) par[, c("stage", "gdd_end")] else stages
    st <- st[order(st$gdd_end), , drop = FALSE]

    d <- cl$data
    d <- d[order(d$unit_id, d$season_id, d$date), , drop = FALSE]
    d$gdd <- growing_degree_days(d$tmin, d$tmax, t_base = tb, t_upper = tu)

    ## ave() accumulates within each unit-season and writes back in place;
    ## split()/unlist() would reorder the groups and misalign the rows
    key <- paste(d$unit_id, d$season_id, sep = "\r")
    d$gdd_cum <- stats::ave(d$gdd, key, FUN = cumsum)

    ## breaks start at 0 so that day one of the season falls in the first stage
    idx <- findInterval(d$gdd_cum, c(0, st$gdd_end))
    idx[idx < 1L] <- 1L
    idx[idx > nrow(st)] <- nrow(st)
    d$stage <- st$stage[idx]
    d$stage <- factor(d$stage, levels = st$stage)

    p$layers[[layer]]$data <- d

    gk <- paste(d$unit_id, d$season_id, as.character(d$stage), sep = "\r")
    sp <- split(seq_len(nrow(d)), gk)
    w <- do.call(rbind, lapply(sp, function(i) {
        data.frame(unit_id = d$unit_id[i[1L]], season_id = d$season_id[i[1L]],
                   stage = as.character(d$stage[i[1L]]),
                   start = min(d$date[i]), end = max(d$date[i]),
                   days = length(i), gdd_end = max(d$gdd_cum[i]),
                   stringsAsFactors = FALSE)
    }))
    rownames(w) <- NULL
    p$windows <- w[order(w$unit_id, w$season_id, w$start), , drop = FALSE]
    rownames(p$windows) <- NULL

    prov_add(p, "phenology_windows",
             sprintf("crop=%s t_base=%s t_upper=%s stages=%s",
                     crop, tb, tu, paste(st$stage, collapse = "/")))
}
