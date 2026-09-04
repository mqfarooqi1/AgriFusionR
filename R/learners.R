## Adapters to established implementations. Nothing here reimplements a
## learning algorithm: each entry is a thin translation between the package's
## (x, y) convention and somebody else's well-tested code. Every adapter is
## single-threaded by default, both because explanation issues hundreds of
## predict calls and because CRAN asks it of examples and tests.

#' @keywords internal
#' @noRd
.arg_default <- function(args, name, value) {
    if (is.null(args[[name]])) args[[name]] <- value
    args
}

## -- k nearest neighbours, written out because it needs no dependency -------
#' @keywords internal
#' @noRd
.knn_fit <- function(x, y, k = 5L, ...) {
    m <- as.matrix(x)
    ctr <- colMeans(m)
    scl <- apply(m, 2L, stats::sd)
    scl[!is.finite(scl) | scl == 0] <- 1
    list(x = scale(m, center = ctr, scale = scl), y = y,
         k = max(1L, min(as.integer(k), length(y))), center = ctr, scale = scl)
}

#' @keywords internal
#' @noRd
.knn_predict <- function(object, newx, ...) {
    nm <- scale(as.matrix(newx), center = object$center, scale = object$scale)
    vapply(seq_len(nrow(nm)), function(i) {
        d <- colSums((t(object$x) - nm[i, ])^2)
        mean(object$y[order(d)[seq_len(object$k)]])
    }, 0)
}

## -- stacked ensemble -------------------------------------------------------

#' @keywords internal
#' @noRd
.stack_weights <- function(P, y) {
    ## non-negative least squares by bounded optimisation, then normalised;
    ## constraining weights to be non-negative is what keeps a stack from
    ## cancelling two base learners against each other and overfitting
    k <- ncol(P)
    obj <- function(w) sum((P %*% w - y)^2)
    st <- rep(1 / k, k)
    fit <- try(stats::optim(st, obj, method = "L-BFGS-B",
                            lower = rep(0, k), upper = rep(1, k)),
               silent = TRUE)
    w <- if (inherits(fit, "try-error")) st else pmax(fit$par, 0)
    if (sum(w) <= 0) w <- st
    w / sum(w)
}

#' @keywords internal
#' @noRd
.stack_fit <- function(x, y, base = NULL, folds = 5L, ...) {
    base <- base %||% c("ranger", "enet", "cubist", "knn")

    ## A name that is not registered at all is almost always a typo, and
    ## dropping it silently hides the mistake: the stack then runs without a
    ## base learner the caller believed was in it. A learner that is registered
    ## but whose package is absent is a different case, and is skipped quietly.
    unknown <- base[!base %in% names(.afr$learners)]
    if (length(unknown)) {
        warning("ignoring unregistered base learner(s): ",
                paste(unknown, collapse = ", "),
                ". See list_learners() for the available names.",
                call. = FALSE)
    }
    base <- Filter(function(b) {
        l <- .afr$learners[[b]]
        !is.null(l) && all(vapply(l$requires, .have_pkg, TRUE))
    }, base)
    if (length(base) < 2L) {
        stop("stacking needs at least two available base learners.",
             call. = FALSE)
    }
    n <- nrow(x)
    folds <- max(2L, min(as.integer(folds), n %/% 2L))
    grp <- ((sample.int(n) - 1L) %% folds) + 1L

    P <- matrix(NA_real_, n, length(base), dimnames = list(NULL, base))
    for (b in seq_along(base)) {
        lb <- .afr$learners[[base[b]]]
        for (g in seq_len(folds)) {
            tr <- which(grp != g); te <- which(grp == g)
            fb <- lb$fit(x[tr, , drop = FALSE], y[tr])
            P[te, b] <- lb$predict(fb, x[te, , drop = FALSE])
        }
    }
    ok <- stats::complete.cases(P)
    w <- .stack_weights(P[ok, , drop = FALSE], y[ok])
    fits <- lapply(base, function(b) .afr$learners[[b]]$fit(x, y))
    names(fits) <- base
    list(base = base, weights = stats::setNames(w, base), fits = fits)
}

#' @keywords internal
#' @noRd
.stack_predict <- function(object, newx, ...) {
    P <- vapply(object$base, function(b) {
        .afr$learners[[b]]$predict(object$fits[[b]], newx)
    }, numeric(nrow(newx)))
    if (is.null(dim(P))) P <- matrix(P, nrow = nrow(newx))
    as.numeric(P %*% object$weights)
}

#' Stack weights from a fitted ensemble
#'
#' Reports how much each base learner contributed to a `"stack"` model, which
#' is usually more informative than the ensemble's accuracy alone: a stack that
#' puts all its weight on one learner is telling you the others added nothing.
#'
#' @param model A model fitted by [train_model()] with `algorithm = "stack"`.
#' @return A named numeric vector of weights summing to one.
#' @seealso [train_model()], [list_learners()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 14, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' set.seed(1)
#' m <- train_model(p, "yield", algorithm = "stack", k = 3,
#'                  compare_random = FALSE)
#' stack_weights(m)
#' @export
stack_weights <- function(model) {
    if (!inherits(model, "agri_model") || !identical(model$learner, "stack")) {
        stop("`model` must be an agri_model fitted with algorithm = 'stack'.",
             call. = FALSE)
    }
    model$fit$weights
}

## -- registration -----------------------------------------------------------

#' @keywords internal
#' @noRd
.register_builtin_learners <- function() {
    register_learner(
        "lm",
        fit = function(x, y, ...) stats::lm(y ~ ., data = cbind(y = y, x)),
        predict = function(object, newx, ...) {
            as.numeric(stats::predict(object, newdata = newx))
        },
        description = "Ordinary least squares; always available")

    register_learner(
        "glm",
        fit = function(x, y, family = stats::gaussian(), ...) {
            stats::glm(y ~ ., data = cbind(y = y, x), family = family)
        },
        predict = function(object, newx, ...) {
            as.numeric(stats::predict(object, newdata = newx,
                                      type = "response"))
        },
        description = "Generalised linear model; pass `family` to change it")

    register_learner(
        "knn", fit = .knn_fit, predict = .knn_predict,
        description = "k nearest neighbours on standardised predictors")

    register_learner(
        "ranger",
        fit = function(x, y, ...) {
            args <- list(y = y, x = x, ...)
            args <- .arg_default(args, "num.trees", 500L)
            args <- .arg_default(args, "num.threads", 1L)
            do.call(ranger::ranger, args)
        },
        predict = function(object, newx, ...) {
            stats::predict(object, data = newx, num.threads = 1L)$predictions
        },
        requires = "ranger", description = "Random forest via 'ranger'")

    register_learner(
        "xgboost",
        fit = function(x, y, ...) {
            args <- list(...)
            nrounds <- args$nrounds %||% 300L
            args$nrounds <- NULL
            pars <- utils::modifyList(
                list(objective = "reg:squarederror", nthread = 1L,
                     eta = 0.05, max_depth = 5L, subsample = 0.8), args)
            d <- xgboost::xgb.DMatrix(as.matrix(x), label = y)
            xgboost::xgb.train(params = pars, data = d, nrounds = nrounds)
        },
        predict = function(object, newx, ...) {
            as.numeric(stats::predict(
                object, xgboost::xgb.DMatrix(as.matrix(newx))))
        },
        requires = "xgboost", description = "Gradient boosting via 'xgboost'")

    register_learner(
        "cubist",
        fit = function(x, y, ...) {
            args <- .arg_default(list(x = x, y = y, ...), "committees", 10L)
            do.call(Cubist::cubist, args)
        },
        predict = function(object, newx, ...) {
            as.numeric(stats::predict(object, newx))
        },
        requires = "Cubist",
        description = "Rule-based model trees via 'Cubist'")

    register_learner(
        "enet",
        fit = function(x, y, alpha = 0.5, ...) {
            glmnet::cv.glmnet(as.matrix(x), y, alpha = alpha, ...)
        },
        predict = function(object, newx, ...) {
            as.numeric(stats::predict(object, newx = as.matrix(newx),
                                      s = "lambda.min"))
        },
        requires = "glmnet",
        description = "Elastic net with lambda by cross-validation ('glmnet')")

    register_learner(
        "svm",
        fit = function(x, y, ...) {
            kernlab::ksvm(as.matrix(x), y, type = "eps-svr", ...)
        },
        predict = function(object, newx, ...) {
            as.numeric(kernlab::predict(object, as.matrix(newx)))
        },
        requires = "kernlab",
        description = "Support vector regression via 'kernlab'")

    register_learner(
        "gam",
        ## smooths are used only where there is data to support them; with many
        ## features relative to rows a smooth per predictor cannot be estimated
        fit = function(x, y, k = 4L, ...) {
            nu <- vapply(x, function(v) length(unique(v[!is.na(v)])), 1L)
            room <- nrow(x) > 6 * ncol(x)
            trm <- ifelse(room & nu >= 10L,
                          sprintf("s(%s, k=%d)", names(x), k), names(x))
            f <- stats::as.formula(paste("y ~", paste(trm, collapse = " + ")))
            mgcv::gam(f, data = cbind(y = y, x), ...)
        },
        predict = function(object, newx, ...) {
            as.numeric(mgcv::predict.gam(object, newdata = newx))
        },
        requires = "mgcv",
        description = "Generalised additive model via 'mgcv'")

    register_learner(
        "stack", fit = .stack_fit, predict = .stack_predict,
        description = paste("Stacked ensemble of the available base learners,",
                            "weighted by non-negative least squares"))
}
