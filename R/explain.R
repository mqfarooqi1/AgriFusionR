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
#' @section Which method answers which question:
#' \describe{
#'   \item{`"importance"`}{How much does the model rely on this feature?
#'     Measured out of fold, so it reflects generalisation rather than
#'     memorisation.}
#'   \item{`"pdp"`}{What shape is the relationship, averaged over everything
#'     else? Misleading when features are strongly correlated, because it
#'     averages over combinations that never occur.}
#'   \item{`"ale"`}{The same question, but accumulated over local differences
#'     within narrow windows of the feature, so it never evaluates the model
#'     on impossible combinations. Prefer it to partial dependence whenever
#'     the predictors are correlated, which for weather features they always
#'     are (Apley and Zhu, 2020).}
#'   \item{`"ice"`}{Partial dependence for each observation separately.
#'     Curves that fan out reveal interactions that the averaged curve hides.}
#'   \item{`"shap"`}{Exact tree SHAP values, attributing each prediction among
#'     the features. Requires the \pkg{treeshap} package and a tree-based
#'     learner.}
#' }
#'
#' @param object A model fitted by [train_model()].
#' @param method Which explanation to compute; see the section above.
#' @param features Features to examine. Defaults to all for `"importance"` and
#'   to the five most important otherwise.
#' @param n_perm Number of shuffles per feature and fold. The function uses the
#'   ambient random state; call [set.seed()] first for reproducibility.
#' @param grid Number of grid points for partial dependence.
#' @param ... Ignored.
#' @return A data frame. For `"importance"`, one row per feature with the mean
#'   and standard deviation of the error increase. For `"pdp"` and `"ale"`, one
#'   row per feature and grid value. For `"ice"`, one row per observation,
#'   feature and grid value. For `"shap"`, one row per observation and feature.
#' @references Apley, D. W. & Zhu, J. (2020) "Visualizing the effects of
#'   predictor variables in black box supervised learning models." Journal of
#'   the Royal Statistical Society Series B 82, 1059-1086.
#'   \doi{10.1111/rssb.12377}
#' @seealso [train_model()], [uncertainty()]
#' @examples
#' # aggregated with one statistic, and few shuffles, to keep the example
#' # quick; use the defaults in real work
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' set.seed(1)
#' head(explain(m, n_perm = 2), 5)
#' head(explain(m, "ale", features = "prcp_sum_grain_fill", grid = 6))
#' @export
explain <- function(object, method = c("importance", "pdp", "ale", "ice",
                                       "shap"),
                    features = NULL, n_perm = 5, grid = 20, ...) {
    UseMethod("explain")
}

#' @rdname explain
#' @export
explain.agri_model <- function(object, method = c("importance", "pdp", "ale",
                                                  "ice", "shap"),
                               features = NULL, n_perm = 5, grid = 20, ...) {
    method <- match.arg(method)
    if (method == "importance") {
        return(.imp_oof(object, features %||% names(object$X), n_perm))
    }
    if (method == "shap") return(.shap(object, features))
    if (is.null(features)) {
        imp <- .imp_oof(object, names(object$X), n_perm = 3)
        features <- utils::head(imp$feature, 5)
    }
    switch(method,
           pdp = .pdp(object, features, grid),
           ale = .ale(object, features, grid),
           ice = .ice(object, features, grid))
}

## Accumulated local effects. Rather than averaging predictions over the whole
## data set at each grid value, which asks the model about feature combinations
## that never occur, this averages the *difference* the feature makes within
## each narrow window and accumulates those differences.
#' @keywords internal
#' @noRd
.ale <- function(object, features, grid) {
    X <- .impute_apply(object$X, object$medians)
    lrn <- object$learner_obj
    res <- lapply(features, function(v) {
        z <- stats::quantile(X[[v]], probs = seq(0, 1, length.out = grid + 1L),
                             na.rm = TRUE, names = FALSE, type = 7)
        z <- unique(z)
        if (length(z) < 3L) return(NULL)
        bin <- findInterval(X[[v]], z, all.inside = TRUE)
        d <- vapply(seq_len(length(z) - 1L), function(b) {
            i <- which(bin == b)
            if (!length(i)) return(0)
            lo <- X[i, , drop = FALSE]; hi <- lo
            lo[[v]] <- z[b]; hi[[v]] <- z[b + 1L]
            mean(lrn$predict(object$fit, hi) - lrn$predict(object$fit, lo))
        }, 0)
        acc <- c(0, cumsum(d))
        data.frame(feature = v, value = z, effect = acc - mean(acc),
                   stringsAsFactors = FALSE)
    })
    out <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
    rownames(out) <- NULL
    out
}

## Individual conditional expectation: one curve per observation. Curves that
## fan out are evidence of an interaction that partial dependence averages away.
#' @keywords internal
#' @noRd
.ice <- function(object, features, grid, max_curves = 40L) {
    X <- .impute_apply(object$X, object$medians)
    lrn <- object$learner_obj
    keep <- if (nrow(X) > max_curves) {
        round(seq(1, nrow(X), length.out = max_curves))
    } else seq_len(nrow(X))
    res <- lapply(features, function(v) {
        rng <- range(X[[v]], na.rm = TRUE)
        if (!is.finite(rng[1L]) || rng[1L] == rng[2L]) return(NULL)
        gs <- seq(rng[1L], rng[2L], length.out = grid)
        do.call(rbind, lapply(gs, function(g) {
            xx <- X[keep, , drop = FALSE]
            xx[[v]] <- g
            data.frame(feature = v, id = keep, value = g,
                       prediction = lrn$predict(object$fit, xx),
                       stringsAsFactors = FALSE)
        }))
    })
    out <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
    rownames(out) <- NULL
    out
}

#' @keywords internal
#' @noRd
.shap <- function(object, features = NULL, max_rows = 200L) {
    if (!.have_pkg("treeshap")) {
        stop("SHAP values need the 'treeshap' package.", call. = FALSE)
    }
    X <- .impute_apply(object$X, object$medians)
    if (nrow(X) > max_rows) X <- X[round(seq(1, nrow(X), length.out = max_rows)), ]
    uni <- switch(
        object$learner,
        ranger = treeshap::ranger.unify(object$fit, X),
        xgboost = treeshap::xgboost.unify(object$fit, X),
        stop("SHAP is available for tree learners ('ranger', 'xgboost'); ",
             "this model uses '", object$learner, "'.", call. = FALSE))
    s <- treeshap::treeshap(uni, X, verbose = FALSE)$shaps
    if (!is.null(features)) s <- s[, intersect(features, names(s)), drop = FALSE]
    out <- data.frame(row = rep(seq_len(nrow(s)), ncol(s)),
                      feature = rep(names(s), each = nrow(s)),
                      shap = unlist(s, use.names = FALSE),
                      stringsAsFactors = FALSE)
    rownames(out) <- NULL
    out
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
