## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

#' Attach a covariate layer to a project
#'
#' Fetches covariates from a registered source and attaches them to the
#' project, keyed to the management unit and season. `add_climate()`,
#' `add_soil()` and `add_satellite()` differ only in the layer they write to
#' and the sources they expect; all three are thin calls to the source
#' registry, so a source added with [register_source()] is usable immediately.
#'
#' Nothing is fetched twice: a layer already present is returned unchanged
#' unless `overwrite = TRUE`.
#'
#' @param p An [agri_project()].
#' @param source Name of a registered source. See [list_sources()].
#' @param layer Name to store the layer under.
#' @param overwrite Replace an existing layer of the same name.
#' @param ... Passed to the source's `fetch` function.
#' @return The project, with the layer attached and the operation recorded in
#'   its provenance.
#' @seealso [register_source()], [list_sources()], [build_features()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
#' p <- add_climate(p, source = "demo")
#' names(p$layers)
#' head(p$layers$climate$data)
#' @export
add_layer <- function(p, source, layer, overwrite = FALSE, ...) {
    if (!inherits(p, "agri_project")) {
        stop("`p` must be an agri_project.", call. = FALSE)
    }
    if (!is.null(p$layers[[layer]]) && !overwrite) {
        message("layer '", layer, "' is already present; ",
                "pass overwrite = TRUE to refetch.")
        return(p)
    }
    src <- .get_source(source)
    dat <- src$fetch(units = units_of(p), seasons = seasons_of(p), ...)
    if (!is.data.frame(dat) || !nrow(dat)) {
        stop("source '", source, "' returned no data.", call. = FALSE)
    }
    need <- if (src$kind == "series") c("unit_id", "date") else "unit_id"
    miss <- setdiff(need, names(dat))
    if (length(miss)) {
        stop("source '", source, "' must return column(s): ",
             paste(miss, collapse = ", "), call. = FALSE)
    }
    if (src$kind == "series" && !"season_id" %in% names(dat)) {
        stop("series source '", source, "' must return a 'season_id' column ",
             "so its rows can be keyed to a season.", call. = FALSE)
    }
    p$layers[[layer]] <- list(name = layer, source = source, kind = src$kind,
                              provides = src$provides, data = dat)
    prov_add(p, paste0("add_layer:", layer),
             sprintf("source=%s kind=%s rows=%d vars=%s", source, src$kind,
                     nrow(dat), paste(src$provides, collapse = "/")))
}

#' @rdname add_layer
#' @export
add_climate <- function(p, source = "demo", layer = "climate",
                        overwrite = FALSE, ...) {
    add_layer(p, source = source, layer = layer, overwrite = overwrite, ...)
}

#' @rdname add_layer
#' @export
add_soil <- function(p, source = "demo_soil", layer = "soil",
                     overwrite = FALSE, ...) {
    add_layer(p, source = source, layer = layer, overwrite = overwrite, ...)
}

#' @rdname add_layer
#' @export
add_satellite <- function(p, source, layer = "satellite",
                          overwrite = FALSE, ...) {
    add_layer(p, source = source, layer = layer, overwrite = overwrite, ...)
}

## Built-in sources --------------------------------------------------------

#' @keywords internal
#' @noRd
.fetch_demo_climate <- function(units, seasons, ...) {
    rows <- lapply(seq_len(nrow(seasons)), function(i) {
        u <- units[units$unit_id == seasons$unit_id[i], , drop = FALSE]
        if (!nrow(u)) return(NULL)
        dates <- seq(seasons$start[i], seasons$end[i], by = "day")
        w <- .synthetic_weather(u$unit_id[1L], u$x[1L], u$y[1L], dates)
        cbind(unit_id = seasons$unit_id[i], season_id = seasons$season_id[i], w)
    })
    do.call(rbind, rows)
}

#' @keywords internal
#' @noRd
.fetch_demo_soil <- function(units, seasons, ...) {
    data.frame(unit_id = units$unit_id,
               clay = .demo_clay(units$x, units$y),
               sand = round(100 - .demo_clay(units$x, units$y) -
                                15 - 5 * cos(units$x / 2.1), 1),
               stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
.fetch_power <- function(units, seasons, pars = c("T2M_MIN", "T2M_MAX",
                                                  "PRECTOTCORR"), ...) {
    if (!.have_pkg("nasapower")) {
        stop("source 'power' needs the 'nasapower' package.", call. = FALSE)
    }
    rows <- lapply(seq_len(nrow(seasons)), function(i) {
        u <- units[units$unit_id == seasons$unit_id[i], , drop = FALSE]
        got <- nasapower::get_power(
            community = "ag", temporal_api = "daily", pars = pars,
            lonlat = c(u$x[1L], u$y[1L]),
            dates = c(as.character(seasons$start[i]),
                      as.character(seasons$end[i])))
        got <- as.data.frame(got)
        data.frame(unit_id = seasons$unit_id[i],
                   season_id = seasons$season_id[i],
                   date = as.Date(got$YYYYMMDD),
                   tmin = got$T2M_MIN, tmax = got$T2M_MAX,
                   prcp = got$PRECTOTCORR, stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
}

#' @keywords internal
#' @noRd
.register_builtin_sources <- function() {
    register_source(
        "demo", .fetch_demo_climate, provides = c("tmin", "tmax", "prcp"),
        kind = "series", requires_network = FALSE,
        description = "Deterministic synthetic daily weather, offline")
    register_source(
        "demo_soil", .fetch_demo_soil, provides = c("clay", "sand"),
        kind = "static", requires_network = FALSE,
        description = "Deterministic synthetic soil texture, offline")
    register_source(
        "power", .fetch_power, provides = c("tmin", "tmax", "prcp"),
        kind = "series", requires_network = TRUE,
        description = "NASA POWER daily agroclimatology via 'nasapower'")
}

.onLoad <- function(libname, pkgname) {
    .register_builtin_sources()
    .register_remote_sources()
    .register_builtin_learners()
}
