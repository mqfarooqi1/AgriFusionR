## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

#' @keywords internal
#' @noRd
.stat1 <- function(v, what) {
    v <- v[!is.na(v)]
    if (!length(v)) return(NA_real_)
    switch(what,
           mean = mean(v), sum = sum(v), min = min(v), max = max(v),
           sd = if (length(v) > 1L) stats::sd(v) else NA_real_,
           stop("unknown statistic '", what, "'.", call. = FALSE))
}

#' @keywords internal
#' @noRd
.longest_run <- function(flag) {
    flag <- as.logical(flag)
    if (!length(flag) || !any(flag, na.rm = TRUE)) return(0L)
    r <- rle(flag)
    max(r$lengths[r$values %in% TRUE])
}

## Aggregate the numeric columns of a daily layer within each unit-season-group
## and pivot to one row per unit-season. Built by hand rather than with
## reshape() so that absent combinations become NA predictably.
#' @keywords internal
#' @noRd
.agg_wide <- function(d, grp, vars, stats) {
    full <- paste(d$unit_id, d$season_id, grp, sep = "\r")
    sp <- split(seq_len(nrow(d)), full)

    recs <- vector("list", length(sp) * length(vars) * length(stats))
    n <- 0L
    for (k in names(sp)) {
        i <- sp[[k]]
        pp <- strsplit(k, "\r", fixed = TRUE)[[1L]]
        for (v in vars) {
            for (st in stats) {
                n <- n + 1L
                recs[[n]] <- list(unit_id = pp[1L], season_id = pp[2L],
                                  feature = paste(v, st, pp[3L], sep = "_"),
                                  value = .stat1(d[[v]][i], st))
            }
        }
    }
    recs <- recs[seq_len(n)]
    long <- data.frame(
        unit_id   = vapply(recs, `[[`, "", "unit_id"),
        season_id = vapply(recs, `[[`, "", "season_id"),
        feature   = vapply(recs, `[[`, "", "feature"),
        value     = vapply(recs, `[[`, 0, "value"),
        stringsAsFactors = FALSE)

    ids <- unique(long[, c("unit_id", "season_id"), drop = FALSE])
    rownames(ids) <- NULL
    idkey <- paste(ids$unit_id, ids$season_id, sep = "\r")
    feats <- unique(long$feature)
    m <- matrix(NA_real_, nrow(ids), length(feats),
                dimnames = list(NULL, feats))
    m[cbind(match(paste(long$unit_id, long$season_id, sep = "\r"), idkey),
            match(long$feature, feats))] <- long$value
    cbind(ids, as.data.frame(m, check.names = FALSE))
}

#' Build the model design matrix
#'
#' Reduces every attached layer to one row per management unit and season,
#' which is the key the whole package is organised around.
#'
#' Daily layers are aggregated within phenological stage by default, so that a
#' feature such as `prcp_sum_grain_fill` carries the same meaning across sites
#' that sowed weeks apart. Aggregating by calendar month instead is available
#' for comparison, and is the usual practice in the literature; it is offered
#' so the difference can be measured rather than assumed.
#'
#' Stress counters are derived before aggregation: days above the heat
#' threshold, days below freezing, dry days, and the longest dry spell in the
#' season.
#'
#' @param p An [agri_project()] with at least one layer attached. For
#'   `aggregation = "phenology"`, [phenology_windows()] must have been run.
#' @param aggregation How to group days within a season.
#' @param stats Statistics to compute for each variable and group.
#' @param stress Whether to derive stress-day counters.
#' @param heat_threshold Daily maximum temperature, in degrees Celsius, above
#'   which a day counts as heat stress.
#' @param dry_threshold Daily rainfall, in millimetres, below which a day
#'   counts as dry.
#' @return The project, with `features` populated.
#' @seealso [phenology_windows()], [check_project()], [train_model()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 6, n_seasons = 2))
#' p <- add_climate(p, source = "demo")
#' p <- phenology_windows(p)
#' p <- build_features(p)
#' dim(p$features)
#' @export
build_features <- function(p, aggregation = c("phenology", "monthly", "season"),
                           stats = c("mean", "sum", "min", "max"),
                           stress = TRUE, heat_threshold = 30,
                           dry_threshold = 1) {
    aggregation <- match.arg(aggregation)
    if (!length(p$layers)) {
        stop("no layers attached; call add_climate() or add_soil() first.",
             call. = FALSE)
    }
    feat <- unique(seasons_of(p)[, c("unit_id", "season_id"), drop = FALSE])
    rownames(feat) <- NULL

    for (ln in names(p$layers)) {
        L <- p$layers[[ln]]
        if (identical(L$kind, "static")) {
            vars <- setdiff(names(L$data), "unit_id")
            feat <- merge(feat, L$data[, c("unit_id", vars), drop = FALSE],
                          by = "unit_id", all.x = TRUE)
            next
        }
        d <- L$data
        if (aggregation == "phenology" && !"stage" %in% names(d)) {
            stop("layer '", ln, "' has no phenological stages; run ",
                 "phenology_windows() first, or choose another aggregation.",
                 call. = FALSE)
        }
        grp <- switch(aggregation,
                      phenology = as.character(d$stage),
                      monthly   = paste0("m", format(d$date, "%m")),
                      season    = "season")

        if (stress) {
            if ("tmax" %in% names(d)) {
                d$heat_day <- as.numeric(d$tmax > heat_threshold)
            }
            if ("tmin" %in% names(d)) d$frost_day <- as.numeric(d$tmin < 0)
            if ("prcp" %in% names(d)) {
                d$dry_day <- as.numeric(d$prcp < dry_threshold)
            }
        }
        drop <- c("unit_id", "season_id", "date", "stage", "gdd", "gdd_cum")
        vars <- setdiff(names(d), drop)
        vars <- vars[vapply(d[vars], is.numeric, TRUE)]
        counters <- intersect(c("heat_day", "frost_day", "dry_day"), vars)
        plain <- setdiff(vars, counters)

        if (length(plain)) {
            feat <- merge(feat, .agg_wide(d, grp, plain, stats),
                          by = c("unit_id", "season_id"), all.x = TRUE)
        }
        if (length(counters)) {
            feat <- merge(feat, .agg_wide(d, grp, counters, "sum"),
                          by = c("unit_id", "season_id"), all.x = TRUE)
        }
        if (stress && "dry_day" %in% names(d)) {
            sp <- split(seq_len(nrow(d)),
                        paste(d$unit_id, d$season_id, sep = "\r"))
            spell <- do.call(rbind, lapply(names(sp), function(k) {
                pp <- strsplit(k, "\r", fixed = TRUE)[[1L]]
                data.frame(unit_id = pp[1L], season_id = pp[2L],
                           max_dry_spell = .longest_run(d$dry_day[sp[[k]]]),
                           stringsAsFactors = FALSE)
            }))
            feat <- merge(feat, spell, by = c("unit_id", "season_id"),
                          all.x = TRUE)
        }
    }

    ## drop features that carry no information
    num <- vapply(feat, is.numeric, TRUE)
    keep <- !num | vapply(feat, function(v) {
        length(unique(v[!is.na(v)])) > 1L
    }, TRUE)
    dropped <- names(feat)[!keep]
    feat <- feat[, keep, drop = FALSE]

    p$features <- feat
    prov_add(p, "build_features",
             sprintf("aggregation=%s stats=%s features=%d dropped_constant=%d",
                     aggregation, paste(stats, collapse = "/"),
                     ncol(feat) - 2L, length(dropped)))
}
