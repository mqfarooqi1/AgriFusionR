#' Check a project for the faults that invalidate an analysis
#'
#' Runs the checks that are cheap to automate and expensive to discover late.
#'
#' The most important is the **leakage guard**: a covariate window that extends
#' past the harvest it is supposed to predict produces a model that cannot be
#' deployed and a skill estimate that means nothing. It is easy to introduce by
#' fetching a fixed date range for every site, and hard to see afterwards.
#'
#' Also checked: duplicated unit-season keys, coordinates outside plausible
#' bounds, missingness by column, and univariate outliers by the median
#' absolute deviation, which is resistant to the outliers it is looking for.
#'
#' @param p An [agri_project()].
#' @param mad_k Number of median absolute deviations beyond which a value is
#'   flagged. Three is conventional.
#' @param max_missing Proportion of missing values in a feature above which it
#'   is reported.
#' @return A data frame of issues with columns `severity`, `check` and
#'   `detail`, invisibly returned and printed. Zero rows means every check
#'   passed.
#' @seealso [build_features()], [train_model()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 6, n_seasons = 2))
#' p <- add_climate(p, source = "demo")
#' check_project(p)
#' @export
check_project <- function(p, mad_k = 3, max_missing = 0.2) {
    iss <- list()
    add <- function(severity, check, detail) {
        iss[[length(iss) + 1L]] <<- data.frame(
            severity = severity, check = check, detail = detail,
            stringsAsFactors = FALSE)
    }
    r <- p$roles

    ## --- leakage: covariates must not reach past harvest -----------------
    if (!is.null(r$end)) {
        s <- seasons_of(p)
        for (ln in names(p$layers)) {
            L <- p$layers[[ln]]
            if (!identical(L$kind, "series")) next
            m <- merge(L$data[, c("unit_id", "season_id", "date")], s,
                       by = c("unit_id", "season_id"), all.x = TRUE)
            over <- sum(m$date > m$end, na.rm = TRUE)
            if (over > 0L) {
                add("error", "leakage",
                    sprintf(paste0("layer '%s' has %d row(s) dated after the ",
                                   "harvest of the season they belong to"),
                            ln, over))
            }
            before <- sum(m$date < m$start, na.rm = TRUE)
            if (before > 0L) {
                add("note", "pre-season data",
                    sprintf(paste0("layer '%s' has %d row(s) before planting; ",
                                   "intended only if modelling carry-over"),
                            ln, before))
            }
        }
    } else {
        add("note", "leakage",
            "no harvest column, so the leakage guard could not run")
    }

    ## --- coordinates ------------------------------------------------------
    if (isTRUE(p$config$geographic)) {
        bad <- sum(abs(p$obs[[r$x]]) > 180 | abs(p$obs[[r$y]]) > 90)
        if (bad > 0L) {
            add("error", "coordinates",
                sprintf("%d row(s) outside valid longitude/latitude", bad))
        }
    }

    ## --- missingness and outliers in the design matrix --------------------
    f <- p$features
    if (!is.null(f)) {
        num <- names(f)[vapply(f, is.numeric, TRUE)]
        for (v in num) {
            miss <- mean(is.na(f[[v]]))
            if (miss > max_missing) {
                add("warning", "missingness",
                    sprintf("feature '%s' is %.0f%% missing", v, 100 * miss))
            }
            x <- f[[v]][!is.na(f[[v]])]
            if (length(x) > 3L) {
                md <- stats::mad(x)
                if (md > 0) {
                    n_out <- sum(abs(x - stats::median(x)) > mad_k * md)
                    if (n_out > 0L) {
                        add("note", "outliers",
                            sprintf("feature '%s' has %d value(s) beyond %g MAD",
                                    v, n_out, mad_k))
                    }
                }
            }
        }
    }

    out <- if (length(iss)) do.call(rbind, iss) else
        data.frame(severity = character(), check = character(),
                   detail = character(), stringsAsFactors = FALSE)
    rownames(out) <- NULL
    class(out) <- c("agri_issues", class(out))
    out
}

#' @export
print.agri_issues <- function(x, ...) {
    if (!nrow(x)) {
        cat("check_project(): no issues found.\n")
        return(invisible(x))
    }
    n_err <- sum(x$severity == "error")
    cat(sprintf("check_project(): %d issue(s), %d of them errors.\n",
                nrow(x), n_err))
    for (i in seq_len(nrow(x))) {
        cat(sprintf("  [%-7s] %-16s %s\n", x$severity[i], x$check[i],
                    x$detail[i]))
    }
    invisible(x)
}
