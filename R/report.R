#' Write a model card
#'
#' Turns the provenance ledger and the validation results into a model card in
#' Markdown: what was fitted, on what data, validated how, with which caveats.
#'
#' The limitations section is generated from the model's own diagnostics rather
#' than written by hand, so it cannot fall out of step with the results. If
#' random cross-validation would have overstated the model, the card says so.
#'
#' @param object A model fitted by [train_model()].
#' @param file Optional path to write to. The text is always returned.
#' @param top Number of features to list.
#' @param ... Ignored.
#' @return A character vector of Markdown lines, invisibly when written to
#'   file.
#' @seealso [train_model()], [provenance()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)))
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' cat(head(report(m), 20), sep = "\n")
#' @export
report <- function(object, file = NULL, top = 10, ...) UseMethod("report")

#' @rdname report
#' @export
report.agri_model <- function(object, file = NULL, top = 10, ...) {
    m <- object$metrics
    mr <- object$metrics_random
    un <- uncertainty(object)
    imp <- try(.imp_oof(object, names(object$X), n_perm = 3), silent = TRUE)

    L <- c(
        "# Model card",
        "",
        sprintf("Generated %s by AgriFusionR.", format(Sys.Date())),
        "",
        "## What was fitted",
        "",
        sprintf("- Target: `%s`", object$target),
        sprintf("- Learner: `%s`", object$learner),
        sprintf("- Observations: %d", length(object$y)),
        sprintf("- Features: %d", ncol(object$X)),
        sprintf("- Units: %d over %d season(s)",
                length(unique(object$keys$unit_id)),
                length(unique(object$keys$season_id))),
        "",
        "## How it was validated",
        "",
        sprintf("- Scheme: %s, %d folds%s", object$resampling$method,
                object$resampling$k,
                if (object$resampling$buffer > 0)
                    sprintf(", %g buffer", object$resampling$buffer) else ""),
        "",
        "| Resampling | n | RMSE | MAE | R2 | Bias |",
        "|---|---|---|---|---|---|",
        sprintf("| %s (reported) | %d | %.3f | %.3f | %.3f | %+.3f |",
                object$resampling$method, m[["n"]], m[["rmse"]], m[["mae"]],
                m[["r2"]], m[["bias"]]))

    if (!is.null(mr)) {
        L <- c(L, sprintf("| random (for comparison) | %d | %.3f | %.3f | %.3f | %+.3f |",
                          mr[["n"]], mr[["rmse"]], mr[["mae"]], mr[["r2"]],
                          mr[["bias"]]))
    }

    L <- c(L, "",
           sprintf("- Prediction interval at %.0f%%: +/- %.4f (split conformal)",
                   100 * un$level, un$half_width),
           if (!is.na(un$coverage))
               sprintf("- Estimated coverage: %.3f", un$coverage))

    if (!inherits(imp, "try-error") && nrow(imp)) {
        L <- c(L, "", "## Most important features", "",
               "| Feature | Increase in RMSE when shuffled |", "|---|---|",
               sprintf("| `%s` | %.4f |", utils::head(imp$feature, top),
                       utils::head(imp$importance, top)))
    }

    L <- c(L, "", "## Limitations", "")
    lim <- character()
    if (!is.null(mr) && is.finite(mr[["r2"]]) && is.finite(m[["r2"]])) {
        gap <- mr[["r2"]] - m[["r2"]]
        lim <- c(lim, sprintf(
            paste0("- Random cross-validation would have reported an R2 of ",
                   "%.3f against the %.3f reported here, an overstatement of ",
                   "%.3f. Compare against published figures accordingly."),
            mr[["r2"]], m[["r2"]], gap))
    }
    if (is.finite(m[["r2"]]) && m[["r2"]] < 0.3) {
        lim <- c(lim, paste0("- Out-of-fold R2 is below 0.3; the model has ",
                             "little predictive value as it stands."))
    }
    if (length(unique(object$keys$season_id)) < 3L) {
        lim <- c(lim, paste0("- Fewer than three seasons, so year-to-year ",
                             "transferability is untested."))
    }
    if (length(unique(object$keys$unit_id)) < 20L) {
        lim <- c(lim, paste0("- Fewer than twenty units, so the spatial folds ",
                             "are small and the skill estimate is noisy."))
    }
    lim <- c(lim, paste0("- Predictions outside the range of conditions in ",
                         "the training data are extrapolation and are not ",
                         "covered by the interval guarantee."))
    L <- c(L, lim, "", "## Provenance", "")

    pv <- object$provenance
    if (nrow(pv)) {
        L <- c(L, "| Step | Detail |", "|---|---|",
               sprintf("| `%s` | %s |", pv$step, pv$detail))
    }

    L <- c(L, "", "## Methods references", "",
           paste0("- Roberts et al. (2017) Ecography 40, 913-929. ",
                  "doi:10.1111/ecog.02881"),
           paste0("- McMaster & Wilhelm (1997) Agric. For. Meteorol. 87, ",
                  "291-300. doi:10.1016/S0168-1923(97)00027-0"),
           paste0("- Lei et al. (2018) JASA 113, 1094-1111. ",
                  "doi:10.1080/01621459.2017.1307116"))

    if (!is.null(file)) {
        writeLines(L, file)
        return(invisible(L))
    }
    L
}
