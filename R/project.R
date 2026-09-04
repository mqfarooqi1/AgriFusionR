#' Create an agricultural analysis project
#'
#' Builds the object every other function in the package operates on. The unit
#' of observation is a **management unit within a season**: a field, plot or
#' administrative area, together with the window over which the crop grew. Each
#' observation is keyed by `(unit_id, season_id)`, and every covariate layer
#' added later must reduce to that key.
#'
#' Column roles are detected from common names when not given explicitly, so
#' `agri_project(data)` usually works unchanged. Detection is reported by the
#' print method, and can always be overridden.
#'
#' @param data A data frame with one row per management unit and season.
#' @param unit_id,x,y Column names giving the unit identifier and its
#'   coordinates. Detected from names such as `unit_id`, `field`, `lon`, `lat`
#'   when `NULL`.
#' @param season Column naming the season, typically a year. Detected from
#'   `season` or `year`.
#' @param start,end Columns giving the start and end of the growing window as
#'   dates. Detected from names such as `planting`/`sowing` and `harvest`.
#' @param crop Column giving the crop, if more than one is present.
#' @param crs Coordinate reference system as an EPSG code. Only 4326 is
#'   currently treated as geographic; anything else is taken as projected, which
#'   changes how distances are computed.
#' @param cache_dir Directory for cached downloads. Defaults to a session
#'   temporary directory, so nothing is written outside it unless asked.
#' @return An object of class `agri_project`.
#' @seealso [add_climate()], [build_features()], [check_project()]
#' @examples
#' d <- demo_agri_data(n_units = 6, n_seasons = 2)
#' p <- agri_project(d)
#' p
#' @export
agri_project <- function(data, unit_id = NULL, x = NULL, y = NULL,
                         season = NULL, start = NULL, end = NULL,
                         crop = NULL, crs = 4326, cache_dir = NULL) {
    if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
    if (!nrow(data)) stop("`data` has no rows.", call. = FALSE)

    roles <- list(
        unit_id = unit_id %||% .pick(data, c("unit_id", "unit", "field_id",
                                             "field", "site", "plot", "id")),
        x       = x %||% .pick(data, c("x", "lon", "long", "longitude")),
        y       = y %||% .pick(data, c("y", "lat", "latitude")),
        season  = season %||% .pick(data, c("season_id", "season", "year")),
        start   = start %||% .pick(data, c("start", "planting", "planting_date",
                                           "sowing", "sowing_date")),
        end     = end %||% .pick(data, c("end", "harvest", "harvest_date")),
        crop    = crop %||% .pick(data, c("crop", "species")))

    for (r in c("unit_id", "x", "y")) {
        if (is.null(roles[[r]])) {
            stop("could not identify the '", r, "' column; pass it explicitly.",
                 call. = FALSE)
        }
    }
    for (r in c("x", "y")) {
        if (!is.numeric(data[[roles[[r]]]])) {
            stop("column '", roles[[r]], "' must be numeric.", call. = FALSE)
        }
    }

    obs <- data
    obs[[roles$unit_id]] <- as.character(obs[[roles$unit_id]])
    if (is.null(roles$season)) {
        obs$.season_id <- "1"
        roles$season <- ".season_id"
    }
    obs[[roles$season]] <- as.character(obs[[roles$season]])
    for (r in c("start", "end")) {
        if (!is.null(roles[[r]])) obs[[roles[[r]]]] <- as.Date(obs[[roles[[r]]]])
    }

    p <- structure(
        list(obs = obs, roles = roles, layers = list(), windows = NULL,
             features = NULL,
             config = list(crs = crs,
                           cache_dir = cache_dir %||% tempfile("agrifusion_"),
                           geographic = identical(as.integer(crs), 4326L)),
             provenance = .prov_new()),
        class = "agri_project")

    p <- prov_add(p, "agri_project",
                  sprintf("%d observations, %d units, %d seasons",
                          nrow(obs), length(unique(obs[[roles$unit_id]])),
                          length(unique(obs[[roles$season]]))))
    validate_project(p)
}

#' @keywords internal
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a

#' @keywords internal
#' @noRd
.pick <- function(data, candidates) {
    nm <- tolower(names(data))
    hit <- match(candidates, nm)
    hit <- hit[!is.na(hit)]
    if (!length(hit)) NULL else names(data)[hit[1L]]
}

#' @keywords internal
#' @noRd
validate_project <- function(p) {
    if (!inherits(p, "agri_project")) {
        stop("not an agri_project object.", call. = FALSE)
    }
    key <- paste(p$obs[[p$roles$unit_id]], p$obs[[p$roles$season]], sep = "\r")
    if (anyDuplicated(key)) {
        n <- sum(duplicated(key))
        stop("the (unit, season) key is not unique: ", n,
             " duplicated row(s). Each unit may appear once per season.",
             call. = FALSE)
    }
    if (!is.null(p$roles$start) && !is.null(p$roles$end)) {
        bad <- which(p$obs[[p$roles$end]] <= p$obs[[p$roles$start]])
        if (length(bad)) {
            stop("harvest is not after planting in ", length(bad), " row(s).",
                 call. = FALSE)
        }
    }
    p
}

#' Accessors for project components
#'
#' @param p An [agri_project()].
#' @return `units_of()` returns one row per management unit with its
#'   coordinates; `seasons_of()` one row per unit and season with the growing
#'   window; `provenance()` the ledger of operations applied so far.
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 4, n_seasons = 2))
#' units_of(p)
#' head(seasons_of(p))
#' @export
units_of <- function(p) {
    r <- p$roles
    u <- p$obs[!duplicated(p$obs[[r$unit_id]]), c(r$unit_id, r$x, r$y)]
    names(u) <- c("unit_id", "x", "y")
    rownames(u) <- NULL
    u
}

#' @rdname units_of
#' @export
seasons_of <- function(p) {
    r <- p$roles
    cols <- c(r$unit_id, r$season, r$start, r$end, r$crop)
    cols <- cols[!vapply(cols, is.null, TRUE)]
    s <- p$obs[, unlist(cols), drop = FALSE]
    names(s) <- c("unit_id", "season_id",
                  if (!is.null(r$start)) "start",
                  if (!is.null(r$end)) "end",
                  if (!is.null(r$crop)) "crop")
    rownames(s) <- NULL
    s
}

#' @export
print.agri_project <- function(x, ...) {
    r <- x$roles
    cat("<agri_project>\n")
    cat("  observations :", nrow(x$obs), "\n")
    cat("  units        :", length(unique(x$obs[[r$unit_id]])),
        sprintf("(%s)", r$unit_id), "\n")
    cat("  seasons      :", length(unique(x$obs[[r$season]])),
        sprintf("(%s)", r$season), "\n")
    if (!is.null(r$start) && !is.null(r$end)) {
        cat("  window       :", format(min(x$obs[[r$start]])), "to",
            format(max(x$obs[[r$end]])), "\n")
    }
    cat("  extent       : x", sprintf("[%.3f, %.3f]", min(x$obs[[r$x]]),
                                      max(x$obs[[r$x]])),
        " y", sprintf("[%.3f, %.3f]", min(x$obs[[r$y]]), max(x$obs[[r$y]])),
        "\n")
    cat("  layers       :",
        if (length(x$layers)) paste(names(x$layers), collapse = ", ") else "none",
        "\n")
    cat("  windows      :",
        if (is.null(x$windows)) "not derived" else
            paste(length(unique(x$windows$stage)), "phenological stages"), "\n")
    cat("  features     :",
        if (is.null(x$features)) "not built" else
            sprintf("%d x %d", nrow(x$features), ncol(x$features) - 2L), "\n")
    invisible(x)
}
