## Base graphics throughout, so that plotting works in every installation
## without adding a heavy dependency. Palettes come from grDevices::hcl.colors,
## whose defaults are perceptually uniform and safe for colour vision
## deficiency; "Blue-Red 3" is used for anything diverging around zero.

#' @importFrom graphics abline axis box image layout legend lines mtext par
#'   points polygon rect segments text title
#' @importFrom grDevices hcl.colors
NULL

#' @keywords internal
#' @noRd
.pal <- function(n, palette = "Viridis") grDevices::hcl.colors(n, palette)

#' @keywords internal
#' @noRd
.col_map <- function(v, palette = "Viridis", n = 64L, symmetric = FALSE) {
    ok <- is.finite(v)
    rng <- if (!any(ok)) c(0, 1) else range(v[ok])
    if (symmetric) {
        m <- max(abs(rng)); rng <- c(-m, m)
    }
    if (diff(rng) == 0) rng <- rng + c(-0.5, 0.5)
    cols <- .pal(n, palette)
    idx <- as.integer(cut(v, breaks = seq(rng[1L], rng[2L], length.out = n + 1L),
                          include.lowest = TRUE))
    list(col = cols[idx], cols = cols, range = rng)
}

## Draws the scale in the right-hand margin rather than over the data. Sizes
## are derived from the device's line height so the bar keeps its proportions
## whatever the figure size, and nothing is clipped.
#' @keywords internal
#' @noRd
.colour_bar <- function(sc, title = "") {
    usr <- graphics::par("usr")
    h <- diff(usr[3:4])
    ## width of one margin line, in user units
    lw <- graphics::par("csi") * diff(usr[1:2]) / graphics::par("pin")[1L]
    x0 <- usr[2L] + 0.7 * lw
    x1 <- x0 + 0.9 * lw
    y0 <- usr[3L] + 0.15 * h
    y1 <- usr[3L] + 0.70 * h
    n <- length(sc$cols)
    ys <- seq(y0, y1, length.out = n + 1L)
    graphics::rect(x0, ys[-(n + 1L)], x1, ys[-1L], col = sc$cols,
                   border = NA, xpd = NA)
    graphics::rect(x0, y0, x1, y1, border = "grey30", xpd = NA)
    lab <- signif(sc$range, 3)
    graphics::text(x1, c(y0, y1), labels = lab, pos = 4, cex = 0.7, xpd = NA)
    if (nzchar(title)) {
        graphics::text(x0 - 0.1 * lw, (y0 + y1) / 2, labels = title, srt = 90,
                       cex = 0.75, xpd = NA, adj = c(0.5, 1))
    }
    invisible(NULL)
}

#' @keywords internal
#' @noRd
.xylab <- function(geographic) {
    if (isTRUE(geographic)) c("longitude", "latitude") else c("x", "y")
}

#' Plot a project's management units
#'
#' Draws the units in space, sized by how many seasons each was observed in.
#' Worth looking at before modelling: clustered units are the situation that
#' makes random cross-validation misleading, and it is easier to see than to
#' infer.
#'
#' @param x An [agri_project()].
#' @param ... Passed to `plot`.
#' @return `x`, invisibly. Called for the plot.
#' @seealso [plot.agri_resample()], [plot_map()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
#' plot(p)
#' @export
plot.agri_project <- function(x, ...) {
    u <- units_of(x)
    s <- seasons_of(x)
    n_seas <- as.integer(table(factor(s$unit_id, levels = u$unit_id)))
    lab <- .xylab(x$config$geographic)
    plot(u$x, u$y, type = "n", xlab = lab[1L], ylab = lab[2L],
         main = sprintf("%d units, %d observations", nrow(u), nrow(s)), ...)
    graphics::points(u$x, u$y, pch = 21, bg = "grey70", col = "grey20",
                     cex = 0.7 + 1.1 * n_seas / max(1L, max(n_seas)))
    ## collapse the size key when every unit was observed equally often,
    ## otherwise it prints the same entry twice
    rng <- range(n_seas)
    if (rng[1L] == rng[2L]) {
        graphics::legend("topright", cex = 0.75, pch = 21, pt.bg = "grey70",
                         pt.cex = 1.3, bg = "#FFFFFFCC", box.col = "grey70",
                         legend = sprintf("%d season(s) each", rng[1L]))
    } else {
        graphics::legend("topright", cex = 0.75, pt.cex = c(0.9, 1.8),
                         pch = 21, pt.bg = "grey70", bg = "#FFFFFFCC",
                         box.col = "grey70",
                         legend = sprintf("%d season(s)", rng))
    }
    invisible(x)
}

#' Plot a resampling scheme
#'
#' Draws each unit coloured by the fold it is held out in, so that what the
#' blocking actually did can be seen rather than assumed. Blocks that look
#' interleaved are not blocking anything.
#'
#' @param x An [resample_scheme()] object.
#' @param ... Passed to `plot`.
#' @return `x`, invisibly. Called for the plot.
#' @seealso [resample_scheme()], [plot.agri_project()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 24, n_seasons = 2))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' plot(resample_scheme(p, method = "spatial_block", k = 4))
#' @export
plot.agri_resample <- function(x, ...) {
    if (is.null(x$coords)) {
        stop("this scheme carries no coordinates; rebuild it with ",
             "resample_scheme().", call. = FALSE)
    }
    fold <- rep(NA_integer_, x$n)
    for (i in seq_along(x$folds)) fold[x$folds[[i]]$test] <- i
    k <- max(fold, na.rm = TRUE)
    cols <- .pal(max(k, 2L), "Dark 3")
    lab <- .xylab(x$geographic)
    plot(x$coords$x, x$coords$y, type = "n", xlab = lab[1L], ylab = lab[2L],
         main = sprintf("%s, %d folds", x$method, x$k), ...)
    graphics::points(x$coords$x, x$coords$y, pch = 19, cex = 1.1,
                     col = ifelse(is.na(fold), "grey80", cols[fold]))
    graphics::legend("topright", cex = 0.7, pch = 19, col = cols[seq_len(k)],
                     legend = sprintf("fold %d", seq_len(k)),
                     bg = "#FFFFFFCC", box.col = "grey70",
                     ncol = if (k > 5L) 2L else 1L)
    invisible(x)
}

#' Plot a fitted model
#'
#' @param x A model fitted by [train_model()].
#' @param type
#'   `"observed"` plots out-of-fold predictions against the truth with a one to
#'   one line, which is the honest version of the usual fitted-versus-observed
#'   figure;
#'   `"residuals"` plots residuals against the prediction, to expose bias that
#'   a single skill number hides;
#'   `"importance"` draws out-of-fold permutation importance.
#' @param top Number of features for `"importance"`.
#' @param n_perm Shuffles per feature for `"importance"`.
#' @param ... Passed to `plot`.
#' @return `x`, invisibly. Called for the plot.
#' @seealso [plot_map()], [plot_effect()], [plot_uncertainty()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' plot(m)
#' plot(m, type = "residuals")
#' @export
plot.agri_model <- function(x, type = c("observed", "residuals", "importance"),
                            top = 12, n_perm = 3, ...) {
    type <- match.arg(type)
    if (type == "importance") {
        imp <- .imp_oof(x, names(x$X), n_perm)
        imp <- utils::head(imp, top)
        imp <- imp[order(imp$importance), ]
        op <- graphics::par(mar = c(4.5, 12, 3, 2))
        on.exit(graphics::par(op), add = TRUE)
        bp <- graphics::barplot(imp$importance, horiz = TRUE, las = 1,
                                names.arg = imp$feature, cex.names = 0.7,
                                col = .pal(nrow(imp), "Viridis"),
                                border = NA,
                                xlab = "increase in RMSE when shuffled",
                                main = "Out-of-fold permutation importance")
        graphics::abline(v = 0, col = "grey40")
        return(invisible(x))
    }

    ok <- is.finite(x$oof)
    if (type == "observed") {
        r2 <- x$metrics[["r2"]]
        plot(x$oof[ok], x$y[ok], pch = 19, col = "#3B7EA1AA",
             xlab = "out-of-fold prediction", ylab = "observed",
             main = sprintf("%s: %s CV, R2 = %.3f", x$target,
                            x$resampling$method, r2), ...)
        graphics::abline(0, 1, col = "grey30", lwd = 2)
        if (!is.null(x$metrics_random)) {
            graphics::mtext(
                sprintf("random folds would report R2 = %.3f",
                        x$metrics_random[["r2"]]), side = 3, line = 0.1,
                cex = 0.8, col = "grey35")
        }
    } else {
        res <- x$y - x$oof
        plot(x$oof[ok], res[ok], pch = 19, col = "#3B7EA1AA",
             xlab = "out-of-fold prediction", ylab = "residual",
             main = sprintf("%s: residuals", x$target), ...)
        graphics::abline(h = 0, col = "grey30", lwd = 2)
        lo <- try(stats::lowess(x$oof[ok], res[ok]), silent = TRUE)
        if (!inherits(lo, "try-error")) {
            graphics::lines(lo, col = "#C1443C", lwd = 2)
        }
    }
    invisible(x)
}

#' Map predictions, residuals or uncertainty
#'
#' Draws each management unit at its coordinates, coloured by what the model
#' produced there. The uncertainty map is the one worth reading: a model can
#' have acceptable average skill and still be useless over part of its area,
#' and only the map shows where.
#'
#' @param model A model fitted by [train_model()].
#' @param what `"prediction"`, `"residual"` (observed minus out-of-fold
#'   prediction, on a diverging scale centred at zero), or `"uncertainty"`
#'   (the conformal interval half-width, wider where the model is less sure).
#' @param season Optional season to show. Defaults to the first, since
#'   overplotting several seasons at one location hides all but the last.
#' @param level Coverage level for `"uncertainty"`.
#' @param ... Passed to `plot`.
#' @return A data frame of the plotted values, invisibly.
#' @seealso [plot.agri_model()], [uncertainty()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 24, n_seasons = 2))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' m <- train_model(p, "yield", algorithm = "lm", k = 4)
#' plot_map(m, "residual")
#' @export
plot_map <- function(model, what = c("prediction", "residual", "uncertainty"),
                     season = NULL, level = 0.9, ...) {
    what <- match.arg(what)
    if (!inherits(model, "agri_model")) {
        stop("`model` must be a model fitted by train_model().", call. = FALSE)
    }
    u <- units_of(model$project)
    keys <- model$keys
    sel <- if (is.null(season)) keys$season_id == keys$season_id[1L] else
        keys$season_id == as.character(season)
    if (!any(sel)) stop("no observations for that season.", call. = FALSE)

    v <- switch(what,
                prediction = model$oof,
                residual = model$y - model$oof,
                uncertainty = rep(.conformal_q(model$residuals, level),
                                  length(model$y)))
    if (what == "uncertainty") {
        ## a single conformal half-width is constant by construction; what
        ## varies in space is how often the model actually missed, so show the
        ## local absolute error instead and say so
        v <- abs(model$y - model$oof)
    }
    d <- data.frame(unit_id = keys$unit_id[sel], value = v[sel],
                    stringsAsFactors = FALSE)
    d$x <- u$x[match(d$unit_id, u$unit_id)]
    d$y <- u$y[match(d$unit_id, u$unit_id)]

    pal <- if (what == "residual") "Blue-Red 3" else "Viridis"
    sc <- .col_map(d$value, pal, symmetric = (what == "residual"))
    ## widen the right margin so the scale has somewhere to live
    op <- graphics::par(mar = graphics::par("mar") + c(0, 0, 0, 4))
    on.exit(graphics::par(op), add = TRUE)
    lab <- .xylab(model$project$config$geographic)
    ttl <- c(prediction = "predicted", residual = "residual",
             uncertainty = "absolute out-of-fold error")[[what]]
    plot(d$x, d$y, type = "n", xlab = lab[1L], ylab = lab[2L],
         main = sprintf("%s: %s, season %s", model$target, ttl,
                        keys$season_id[sel][1L]), ...)
    graphics::points(d$x, d$y, pch = 21, bg = sc$col, col = "grey25", cex = 1.9)
    .colour_bar(sc, ttl)
    invisible(d)
}

#' Plot a marginal effect
#'
#' Draws accumulated local effects, partial dependence, or individual
#' conditional expectation curves for one feature.
#'
#' Accumulated local effects is the default deliberately. Partial dependence
#' averages the model over feature combinations that may never occur, which for
#' correlated weather features it routinely does; ALE accumulates local
#' differences instead and does not.
#'
#' @param model A model fitted by [train_model()].
#' @param feature Name of the feature to show.
#' @param method `"ale"`, `"pdp"` or `"ice"`.
#' @param grid Number of grid points.
#' @param ... Passed to `plot`.
#' @return The computed effect, invisibly.
#' @seealso [explain()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' plot_effect(m, "prcp_sum_grain_fill")
#' @export
plot_effect <- function(model, feature, method = c("ale", "pdp", "ice"),
                        grid = 20, ...) {
    method <- match.arg(method)
    if (!feature %in% names(model$X)) {
        stop("no feature called '", feature, "'.", call. = FALSE)
    }
    e <- explain(model, method, features = feature, grid = grid)
    if (method == "ice") {
        plot(range(e$value), range(e$prediction), type = "n", xlab = feature,
             ylab = model$target,
             main = sprintf("ICE: %s", feature), ...)
        for (i in unique(e$id)) {
            s <- e[e$id == i, ]
            graphics::lines(s$value, s$prediction, col = "#3B7EA133")
        }
        avg <- tapply(e$prediction, e$value, mean)
        graphics::lines(as.numeric(names(avg)), as.numeric(avg),
                        col = "#C1443C", lwd = 3)
        graphics::legend("topright", bty = "n", cex = 0.75, lwd = c(1, 3),
                         col = c("#3B7EA1", "#C1443C"),
                         legend = c("per observation", "average (PDP)"))
    } else {
        yy <- if (method == "ale") e$effect else e$prediction
        ylb <- if (method == "ale") sprintf("effect on %s", model$target) else
            model$target
        plot(e$value, yy, type = "l", lwd = 2.5, col = "#3B7EA1",
             xlab = feature, ylab = ylb,
             main = sprintf("%s: %s", toupper(method), feature), ...)
        graphics::points(e$value, yy, pch = 19, cex = 0.6, col = "#3B7EA1")
        if (method == "ale") graphics::abline(h = 0, col = "grey60", lty = 2)
        graphics::rug(model$X[[feature]], col = "grey50")
    }
    invisible(e)
}

#' Plot prediction intervals and their coverage
#'
#' Observations are sorted by prediction and drawn with their conformal
#' interval, with the ones the interval missed picked out. A calibrated
#' interval should miss about `1 - level` of them, scattered rather than
#' concentrated at one end.
#'
#' @param model A model fitted by [train_model()].
#' @param level Coverage level.
#' @param ... Passed to `plot`.
#' @return A data frame of predictions, bounds and whether each was covered,
#'   invisibly.
#' @seealso [uncertainty()], [predict.agri_model()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
#' p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
#' m <- train_model(p, "yield", algorithm = "lm", k = 3)
#' plot_uncertainty(m)
#' @export
plot_uncertainty <- function(model, level = 0.9, ...) {
    q <- .conformal_q(model$residuals, level)
    ok <- is.finite(model$oof)
    d <- data.frame(pred = model$oof[ok], obs = model$y[ok])
    d <- d[order(d$pred), ]
    d$lower <- d$pred - q
    d$upper <- d$pred + q
    d$covered <- d$obs >= d$lower & d$obs <= d$upper
    i <- seq_len(nrow(d))

    plot(i, d$obs, type = "n", ylim = range(c(d$lower, d$upper, d$obs)),
         xlab = "observation, ordered by prediction", ylab = model$target,
         main = sprintf("%.0f%% conformal intervals: %.1f%% covered",
                        100 * level, 100 * mean(d$covered)), ...)
    graphics::polygon(c(i, rev(i)), c(d$lower, rev(d$upper)),
                      col = "#3B7EA126", border = NA)
    graphics::lines(i, d$pred, col = "#3B7EA1", lwd = 2)
    graphics::points(i[d$covered], d$obs[d$covered], pch = 19, cex = 0.7,
                     col = "grey35")
    graphics::points(i[!d$covered], d$obs[!d$covered], pch = 19, cex = 0.9,
                     col = "#C1443C")
    graphics::legend("topleft", bty = "n", cex = 0.75, pch = 19,
                     col = c("grey35", "#C1443C"),
                     legend = c("covered", "missed"))
    invisible(d)
}
