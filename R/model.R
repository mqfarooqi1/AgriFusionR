#' @keywords internal
#' @noRd
.metrics <- function(obs, pred) {
    ok <- !is.na(obs) & !is.na(pred)
    o <- obs[ok]; q <- pred[ok]
    if (length(o) < 2L) {
        return(c(n = length(o), rmse = NA_real_, mae = NA_real_,
                 r2 = NA_real_, bias = NA_real_))
    }
    sse <- sum((o - q)^2)
    sst <- sum((o - mean(o))^2)
    c(n = length(o), rmse = sqrt(mean((o - q)^2)), mae = mean(abs(o - q)),
      r2 = if (sst > 0) 1 - sse / sst else NA_real_, bias = mean(q - o))
}

#' @keywords internal
#' @noRd
.impute_apply <- function(x, med) {
    for (v in names(med)) {
        if (!v %in% names(x)) next
        na <- is.na(x[[v]])
        if (any(na)) x[[v]][na] <- med[[v]]
    }
    x
}

#' @keywords internal
#' @noRd
.medians <- function(x) {
    vapply(x, function(v) stats::median(v, na.rm = TRUE), 0)
}

#' @keywords internal
#' @noRd
.run_cv <- function(X, y, lrn, folds, keep_models = TRUE, ...) {
    oof <- rep(NA_real_, length(y))
    models <- vector("list", length(folds))
    for (i in seq_along(folds)) {
        tr <- folds[[i]]$train
        te <- folds[[i]]$test
        med <- .medians(X[tr, , drop = FALSE])
        xtr <- .impute_apply(X[tr, , drop = FALSE], med)
        xte <- .impute_apply(X[te, , drop = FALSE], med)
        fit <- lrn$fit(xtr, y[tr], ...)
        oof[te] <- lrn$predict(fit, xte)
        if (keep_models) models[[i]] <- list(fit = fit, med = med, test = te)
    }
    list(oof = oof, models = models)
}

#' Train and honestly validate a model
#'
#' Fits a model to predict `target` from the features built for the project,
#' estimating skill by spatial resampling rather than random folds.
#'
#' By default the same model is also evaluated with random folds and both
#' results are reported. The difference between them is the amount by which
#' random cross-validation would have overstated the model, and it is worth
#' knowing before any figure is published.
#'
#' Missing predictor values are filled with the median of the training rows of
#' each fold, computed inside the fold so that no information crosses the
#' split.
#'
#' @param p An [agri_project()] with features built.
#' @param target Name of the response column in the project's observations.
#' @param algorithm A registered learner, or `"auto"` to use `"ranger"` when
#'   available and `"lm"` otherwise. See [list_learners()].
#' @param resampling A [resample_scheme()] object. Built automatically when
#'   `NULL`.
#' @param method,k,buffer Passed to [resample_scheme()] when it builds the
#'   scheme itself.
#' @param compare_random Also evaluate with random folds, to quantify the
#'   optimism that random cross-validation would have introduced.
#' @param ... Passed to the learner's `fit` function.
#' @return An object of class `agri_model`.
#' @seealso [resample_scheme()], [explain()], [uncertainty()], [report()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- add_climate(p, source = "demo")
#' p <- phenology_windows(p)
#' p <- build_features(p)
#' m <- train_model(p, target = "yield", algorithm = "lm", k = 3)
#' m
#' @export
train_model <- function(p, target, algorithm = "auto", resampling = NULL,
                        method = "spatial_block", k = 5, buffer = 0,
                        compare_random = TRUE, ...) {
    if (is.null(p$features)) {
        stop("build features first with build_features().", call. = FALSE)
    }
    if (!target %in% names(p$obs)) {
        stop("no column '", target, "' in the project's observations.",
             call. = FALSE)
    }
    if (identical(algorithm, "auto")) {
        algorithm <- if (.have_pkg("ranger")) "ranger" else "lm"
    }
    lrn <- .get_learner(algorithm)

    f <- p$features
    r <- p$roles
    y <- p$obs[[target]][match(paste(f$unit_id, f$season_id, sep = "\r"),
                               paste(p$obs[[r$unit_id]], p$obs[[r$season]],
                                     sep = "\r"))]
    keep <- !is.na(y)
    if (sum(keep) < 5L) {
        stop("fewer than five observations have a value for '", target, "'.",
             call. = FALSE)
    }
    f <- f[keep, , drop = FALSE]
    y <- y[keep]
    p$features <- f

    X <- f[, setdiff(names(f), c("unit_id", "season_id")), drop = FALSE]
    X <- X[, vapply(X, is.numeric, TRUE), drop = FALSE]
    X <- X[, vapply(X, function(v) !all(is.na(v)), TRUE), drop = FALSE]
    if (!ncol(X)) stop("no usable numeric features.", call. = FALSE)
    if (ncol(X) >= nrow(X) / 2) {
        warning(sprintf(paste0(
            "%d features for %d observations. Unregularised linear learners ",
            "will be rank deficient here; prefer a tree-based or penalised ",
            "learner, or pass fewer `stats` to build_features()."),
            ncol(X), nrow(X)), call. = FALSE)
    }

    rs <- resampling %||% resample_scheme(p, method = method, k = k,
                                          buffer = buffer)
    cv <- .run_cv(X, y, lrn, rs$folds, ...)
    met <- .metrics(y, cv$oof)

    met_rand <- NULL
    if (compare_random) {
        rr <- suppressWarnings(resample_scheme(p, method = "random",
                                               k = min(k, nrow(X) %/% 2L)))
        met_rand <- .metrics(y, .run_cv(X, y, lrn, rr$folds,
                                        keep_models = FALSE, ...)$oof)
    }

    med <- .medians(X)
    final <- lrn$fit(.impute_apply(X, med), y, ...)

    p <- prov_add(p, "train_model",
                  sprintf("target=%s learner=%s resampling=%s/%d folds",
                          target, algorithm, rs$method, rs$k))

    structure(list(
        target = target, learner = algorithm, learner_obj = lrn,
        fit = final, medians = med, X = X, y = y,
        keys = f[, c("unit_id", "season_id"), drop = FALSE],
        oof = cv$oof, residuals = y - cv$oof, fold_models = cv$models,
        resampling = rs, metrics = met, metrics_random = met_rand,
        provenance = p$provenance, project = p),
        class = "agri_model")
}

#' @export
print.agri_model <- function(x, ...) {
    cat("<agri_model>\n")
    cat("  target     :", x$target, "\n")
    cat("  learner    :", x$learner, "\n")
    cat("  features   :", ncol(x$X), "\n")
    cat("  resampling :", x$resampling$method,
        sprintf("(%d folds)", x$resampling$k), "\n")
    m <- x$metrics
    cat(sprintf("  spatial CV : RMSE %.3f  MAE %.3f  R2 %.3f  (n=%d)\n",
                m[["rmse"]], m[["mae"]], m[["r2"]], m[["n"]]))
    if (!is.null(x$metrics_random)) {
        mr <- x$metrics_random
        cat(sprintf("  random CV  : RMSE %.3f  MAE %.3f  R2 %.3f\n",
                    mr[["rmse"]], mr[["mae"]], mr[["r2"]]))
        gap <- mr[["r2"]] - m[["r2"]]
        cat(sprintf("  optimism   : random CV overstates R2 by %.3f\n", gap))
    }
    invisible(x)
}

#' Predict from a fitted model
#'
#' @param object A model fitted by [train_model()].
#' @param newdata Optional data frame of features. When omitted, predictions
#'   for the training rows are returned, alongside the out-of-fold predictions,
#'   which are the honest ones.
#' @param interval Attach conformal prediction intervals.
#' @param level Coverage level for the interval.
#' @param ... Ignored.
#' @return A data frame with the keys, `.pred`, and when `newdata` is omitted
#'   `.pred_oof`; plus `.lower` and `.upper` when `interval = TRUE`.
#' @seealso [uncertainty()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)))
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' head(predict(m, interval = TRUE))
#' @export
predict.agri_model <- function(object, newdata = NULL, interval = FALSE,
                               level = 0.9, ...) {
    if (is.null(newdata)) {
        out <- cbind(object$keys,
                     .pred = object$learner_obj$predict(
                         object$fit, .impute_apply(object$X, object$medians)),
                     .pred_oof = object$oof)
    } else {
        miss <- setdiff(names(object$X), names(newdata))
        if (length(miss)) {
            stop("`newdata` is missing feature(s): ",
                 paste(utils::head(miss, 5), collapse = ", "),
                 if (length(miss) > 5) " ..." else "", call. = FALSE)
        }
        nx <- .impute_apply(newdata[, names(object$X), drop = FALSE],
                            object$medians)
        out <- data.frame(.pred = object$learner_obj$predict(object$fit, nx))
    }
    if (interval) {
        q <- .conformal_q(object$residuals, level)
        out$.lower <- out$.pred - q
        out$.upper <- out$.pred + q
    }
    rownames(out) <- NULL
    out
}
