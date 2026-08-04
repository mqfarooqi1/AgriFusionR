## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

## Adapters to established R clients for public environmental data. Each is a
## translation into the package's (unit, season, date) convention; none
## reimplements an API client. All need network access, so they are skipped in
## tests and examples.

#' @keywords internal
#' @noRd
.seasons_by_unit <- function(units, seasons) {
    split(seq_len(nrow(seasons)), seasons$unit_id)
}

## -- CHIRPS rainfall --------------------------------------------------------
#' @keywords internal
#' @noRd
## Defaults to the ClimateSERV backend rather than CHC. CHC streams Cloud
## Optimized GeoTIFFs, which in testing failed with GDAL tile-read errors for
## single-point queries; ClimateSERV returns point values directly and was
## reliable. Pass server = "CHC" if you need the raster path.
.fetch_chirps <- function(units, seasons, server = "ClimateSERV", ...) {
    if (!.have_pkg("chirps")) {
        stop("source 'chirps' needs the 'chirps' package.", call. = FALSE)
    }
    rows <- lapply(seq_len(nrow(seasons)), function(i) {
        u <- units[units$unit_id == seasons$unit_id[i], , drop = FALSE]
        pt <- data.frame(lon = u$x[1L], lat = u$y[1L])
        got <- chirps::get_chirps(
            pt, dates = c(as.character(seasons$start[i]),
                          as.character(seasons$end[i])),
            server = server)
        data.frame(unit_id = seasons$unit_id[i],
                   season_id = seasons$season_id[i],
                   date = as.Date(got$date), prcp = as.numeric(got$chirps),
                   stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
}

## -- Daymet, North America only ---------------------------------------------
#' @keywords internal
#' @noRd
.fetch_daymet <- function(units, seasons, ...) {
    if (!.have_pkg("daymetr")) {
        stop("source 'daymet' needs the 'daymetr' package.", call. = FALSE)
    }
    rows <- lapply(seq_len(nrow(seasons)), function(i) {
        u <- units[units$unit_id == seasons$unit_id[i], , drop = FALSE]
        y1 <- as.integer(format(seasons$start[i], "%Y"))
        y2 <- as.integer(format(seasons$end[i], "%Y"))
        got <- daymetr::download_daymet(
            site = seasons$unit_id[i], lat = u$y[1L], lon = u$x[1L],
            start = y1, end = y2, internal = TRUE, silent = TRUE)$data
        d <- as.Date(paste0(got$year, "-01-01")) + got$yday - 1L
        keep <- d >= seasons$start[i] & d <= seasons$end[i]
        data.frame(unit_id = seasons$unit_id[i],
                   season_id = seasons$season_id[i], date = d[keep],
                   tmin = got[["tmin..deg.c."]][keep],
                   tmax = got[["tmax..deg.c."]][keep],
                   prcp = got[["prcp..mm.day."]][keep],
                   srad = got[["srad..W.m.2."]][keep],
                   stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
}

## -- WorldClim normals, SoilGrids and elevation, all via geodata ------------
#' @keywords internal
#' @noRd
.extract_at <- function(r, units) {
    pts <- as.matrix(units[, c("x", "y"), drop = FALSE])
    v <- terra::extract(r, pts)
    as.data.frame(v)
}

#' @keywords internal
#' @noRd
.fetch_worldclim <- function(units, seasons, var = "bio", res = 10,
                             path = tempdir(), ...) {
    if (!.have_pkg("geodata") || !.have_pkg("terra")) {
        stop("source 'worldclim' needs the 'geodata' and 'terra' packages.",
             call. = FALSE)
    }
    r <- geodata::worldclim_global(var = var, res = res, path = path)
    v <- .extract_at(r, units)
    names(v) <- paste0("wc_", gsub("^wc[0-9._]*", "", names(v)))
    cbind(unit_id = units$unit_id, v)
}

#' @keywords internal
#' @noRd
.fetch_soilgrids <- function(units, seasons,
                             var = c("clay", "sand", "soc", "phh2o"),
                             depth = 15, stat = "mean", path = tempdir(), ...) {
    if (!.have_pkg("geodata") || !.have_pkg("terra")) {
        stop("source 'soilgrids' needs the 'geodata' and 'terra' packages.",
             call. = FALSE)
    }
    out <- data.frame(unit_id = units$unit_id, stringsAsFactors = FALSE)
    for (v in var) {
        r <- geodata::soil_world(var = v, depth = depth, stat = stat,
                                 path = path)
        out[[v]] <- .extract_at(r, units)[, 1L]
    }
    out
}

#' @keywords internal
#' @noRd
.fetch_elevation <- function(units, seasons, res = 0.5, path = tempdir(),
                             ...) {
    if (!.have_pkg("geodata") || !.have_pkg("terra")) {
        stop("source 'elevation' needs the 'geodata' and 'terra' packages.",
             call. = FALSE)
    }
    lon <- mean(range(units$x)); lat <- mean(range(units$y))
    r <- geodata::elevation_global(res = res, path = path)
    e <- .extract_at(r, units)[, 1L]
    ## terrain derivatives are what agronomy actually uses; they need a
    ## neighbourhood, so they come from the raster rather than the point
    slope <- terra::terrain(r, v = "slope", unit = "degrees")
    aspect <- terra::terrain(r, v = "aspect", unit = "degrees")
    data.frame(unit_id = units$unit_id, elevation = e,
               slope = .extract_at(slope, units)[, 1L],
               aspect = .extract_at(aspect, units)[, 1L],
               stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
.register_remote_sources <- function() {
    register_source(
        "chirps", .fetch_chirps, provides = "prcp", kind = "series",
        requires_network = TRUE,
        description = "CHIRPS daily rainfall via the 'chirps' package")
    register_source(
        "daymet", .fetch_daymet,
        provides = c("tmin", "tmax", "prcp", "srad"), kind = "series",
        requires_network = TRUE,
        description = "Daymet daily weather, North America, via 'daymetr'")
    register_source(
        "worldclim", .fetch_worldclim, provides = "wc_*", kind = "static",
        requires_network = TRUE,
        description = "WorldClim climate normals via 'geodata'")
    register_source(
        "soilgrids", .fetch_soilgrids,
        provides = c("clay", "sand", "soc", "phh2o"), kind = "static",
        requires_network = TRUE,
        description = "SoilGrids soil properties via 'geodata'")
    register_source(
        "elevation", .fetch_elevation,
        provides = c("elevation", "slope", "aspect"), kind = "static",
        requires_network = TRUE,
        description = "SRTM elevation and terrain derivatives via 'geodata'")
}
