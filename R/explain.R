## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

#' Explain a fitted model
#'
#' Permutation importance and partial dependence, both computed so that the
#' answer means what it appears to mean.
#'
#' Importance is measured **out of fold**: within each resampling fold, one
#' feature of the held-out rows is shuffled and the increase in that fold's
#' error is recorded. In-sample permutation importance on a flexible learner
#' mostly measures how much the model was able to memorise, which is why it is
#' not offered here.
#'
#' Note that permutation importance is unreliable when features are strongly
#' correlated, which climate features usually are: shuffling one of a pair of
#' near-duplicates leaves the other to carry the signal, so both look
#' unimportant. Treat the ranking as indicative and read it alongside partial
#' dependence.
#'
#' @param object A model fitted by [train_model()].
#' @param method `"importance"` for out-of-fold permutation importance,
#'   `"pdp"` for partial dependence.
#' @param features Features to examine. Defaults to all for `"importance"` and
#'   to the five most important for `"pdp"`.
#' @param n_perm Number of shuffles per feature and fold. The function uses the
#'   ambient random state; call [set.seed()] first for reproducibility.
#' @param grid Number of grid points for partial dependence.
#' @param ... Ignored.
#' @return A data frame: for `"importance"`, one row per feature with the mean
#'   and standard deviation of the error increase; for `"pdp"`, one row per
#'   feature and grid value with the averaged prediction.
#' @seealso [train_model()], [uncertainty()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)))
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' set.seed(1)
#' head(explain(m), 5)
#' @export
explain <- function(object, method = c("importance", "pdp"), features = NULL,
                    n_perm = 5, grid = 20, ...) UseMethod("explain")

#' @rdname explain
#' @export
explain.agri_model <- function(object, method = c("importance", "pdp"),
                               features = NULL, n_perm = 5, grid = 20, ...) {
    method <- match.arg(method)
    if (method == "importance") {
        return(.imp_oof(object, features %||% names(object$X), n_perm))
    }
    if (is.null(features)) {
        imp <- .imp_oof(object, names(object$X), n_perm = 3)
        features <- utils::head(imp$feature, 5)
    }
    .pdp(object, features, grid)
}

#' @keywords internal
#' @noRd
.imp_oof <- function(object, features, n_perm) {
    lrn <- object$learner_obj
    y <- object$y
    acc <- matrix(NA_real_, length(features), length(object$fold_models),
                  dimnames = list(features, NULL))

    for (i in seq_along(object$fold_models)) {
        fm <- object$fold_models[[i]]
        if (is.null(fm)) next
        te <- fm$test
        if (length(te) < 3L) next
        xte <- .impute_apply(object$X[te, , drop = FALSE], fm$med)
        base <- sqrt(mean((y[te] - lrn$predict(fm$fit, xte))^2))
        for (v in features) {
            if (!v %in% names(xte)) next
            d <- vapply(seq_len(n_perm), function(b) {
                xp <- xte
                xp[[v]] <- xp[[v]][sample.int(nrow(xp))]
                sqrt(mean((y[te] - lrn$predict(fm$fit, xp))^2)) - base
            }, 0)
            acc[v, i] <- mean(d)
        }
    }
    out <- data.frame(
        feature = features,
        importance = apply(acc, 1L, mean, na.rm = TRUE),
        sd = apply(acc, 1L, stats::sd, na.rm = TRUE),
        stringsAsFactors = FALSE)
    out <- out[order(-out$importance), , drop = FALSE]
    rownames(out) <- NULL
    out
}

#' @keywords internal
#' @noRd
.pdp <- function(object, features, grid) {
    X <- .impute_apply(object$X, object$medians)
    lrn <- object$learner_obj
    res <- lapply(features, function(v) {
        rng <- range(X[[v]], na.rm = TRUE)
        if (!is.finite(rng[1L]) || rng[1L] == rng[2L]) return(NULL)
        gs <- seq(rng[1L], rng[2L], length.out = grid)
        yh <- vapply(gs, function(g) {
            xx <- X
            xx[[v]] <- g
            mean(lrn$predict(object$fit, xx), na.rm = TRUE)
        }, 0)
        data.frame(feature = v, value = gs, prediction = yh,
                   stringsAsFactors = FALSE)
    })
    out <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
    rownames(out) <- NULL
    out
}
