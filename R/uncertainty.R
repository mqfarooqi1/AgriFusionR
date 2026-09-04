#' @keywords internal
#' @noRd
.conformal_q <- function(res, level = 0.9) {
    r <- abs(res[!is.na(res)])
    n <- length(r)
    if (n < 2L) return(NA_real_)
    h <- min(1, ceiling((n + 1) * level) / n)
    as.numeric(stats::quantile(r, probs = h, type = 1, names = FALSE))
}

#' Prediction intervals by split conformal inference
#'
#' Turns the out-of-fold residuals into prediction intervals with a
#' distribution-free finite-sample coverage guarantee.
#'
#' Conformal inference is used because it is the only interval method that
#' works uniformly across a registry of arbitrary learners: it assumes nothing
#' about the model or the error distribution, only that the calibration and
#' prediction data are exchangeable. Because the residuals come from **spatial**
#' resampling, the resulting intervals inherit that honesty; intervals
#' calibrated on random folds would be too narrow for the same reason random
#' cross-validation is too optimistic.
#'
#' @section Reported coverage:
#' The half-width and the coverage check cannot come from the same residuals
#' without being circular. Coverage is therefore estimated by two-fold
#' splitting of the residual vector: calibrate on one half, measure on the
#' other, and average the two directions.
#'
#' @param object A model fitted by [train_model()].
#' @param level Target coverage, between 0 and 1.
#' @param ... Ignored.
#' @return An object of class `agri_uncertainty` giving the interval
#'   half-width, the target level and the estimated empirical coverage.
#' @references Lei, J., G'Sell, M., Rinaldo, A., Tibshirani, R. J. &
#'   Wasserman, L. (2018) "Distribution-free predictive inference for
#'   regression." Journal of the American Statistical Association 113,
#'   1094-1111. \doi{10.1080/01621459.2017.1307116}
#' @seealso [train_model()], [predict.agri_model()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)))
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' uncertainty(m)
#' @export
uncertainty <- function(object, level = 0.9, ...) UseMethod("uncertainty")

#' @rdname uncertainty
#' @export
uncertainty.agri_model <- function(object, level = 0.9, ...) {
    if (level <= 0 || level >= 1) {
        stop("`level` must be strictly between 0 and 1.", call. = FALSE)
    }
    res <- object$residuals[!is.na(object$residuals)]
    q <- .conformal_q(res, level)

    ## honest coverage: calibrate on one half, measure on the other
    cov <- NA_real_
    if (length(res) >= 8L) {
        a <- seq(1L, length(res), by = 2L)
        b <- setdiff(seq_along(res), a)
        c1 <- mean(abs(res[b]) <= .conformal_q(res[a], level))
        c2 <- mean(abs(res[a]) <= .conformal_q(res[b], level))
        cov <- (c1 + c2) / 2
    }
    structure(list(level = level, half_width = q, coverage = cov,
                   n_calibration = length(res), target = object$target),
              class = "agri_uncertainty")
}

#' @export
print.agri_uncertainty <- function(x, ...) {
    cat("<agri_uncertainty>\n")
    cat("  target        :", x$target, "\n")
    cat("  level         :", x$level, "\n")
    cat(sprintf("  half-width    : %.4f  (interval is prediction +/- this)\n",
                x$half_width))
    cat("  calibration n :", x$n_calibration, "\n")
    if (!is.na(x$coverage)) {
        cat(sprintf("  coverage      : %.3f estimated by split (target %.2f)\n",
                    x$coverage, x$level))
    }
    invisible(x)
}
