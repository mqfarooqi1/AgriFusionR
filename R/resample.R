## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

#' @keywords internal
#' @noRd
.dist_km <- function(x1, y1, x2, y2, geographic = TRUE) {
    if (!geographic) return(sqrt((x1 - x2)^2 + (y1 - y2)^2))
    p <- pi / 180
    a <- sin((y2 - y1) * p / 2)^2 +
        cos(y1 * p) * cos(y2 * p) * sin((x2 - x1) * p / 2)^2
    2 * 6371 * asin(pmin(1, sqrt(a)))
}

#' Build a resampling scheme
#'
#' Constructs the train and test splits used to estimate predictive skill.
#'
#' @section Why the default is spatial:
#' Agricultural observations near one another share weather, soil and
#' management. Under random k-fold cross-validation a test point almost always
#' has a near-duplicate in the training set, so the estimate answers "how well
#' does this interpolate between my own plots" when the question asked is
#' usually "how well does this predict somewhere new". The gap between the two
#' is often large. Roberts et al. (2017) set out the problem and the blocking
#' remedies; Meyer and Pebesma (2021) show how far a model can be trusted
#' outside the space it was trained in.
#'
#' `"random"` remains available, and [train_model()] reports both so the
#' difference can be quantified rather than argued about.
#'
#' @param p An [agri_project()] with features built.
#' @param method
#'   `"spatial_block"` groups units into compact blocks by k-means on their
#'   coordinates and holds out whole blocks;
#'   `"leave_location_out"` holds out whole units;
#'   `"forward_season"` trains on past seasons and tests on the next, never
#'   using the future to predict the past;
#'   `"random"` ignores structure entirely.
#' @param k Number of folds.
#' @param buffer Exclude training rows whose unit lies within this distance of
#'   any test unit. Kilometres when the project is geographic, otherwise
#'   coordinate units. Buffering removes the residual optimism that blocking
#'   alone leaves at block edges.
#' @return An object of class `agri_resample`.
#' @references
#' Roberts, D. R. et al. (2017) "Cross-validation strategies for data with
#' temporal, spatial, hierarchical, or phylogenetic structure." Ecography 40,
#' 913-929. \doi{10.1111/ecog.02881}
#'
#' Meyer, H. & Pebesma, E. (2021) "Predicting into unknown space? Estimating
#' the area of applicability of spatial prediction models." Methods in Ecology
#' and Evolution 12, 1620-1633. \doi{10.1111/2041-210X.13650}
#' @seealso [train_model()]
#' @examples
#' p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 2))
#' p <- add_climate(p, source = "demo")
#' p <- phenology_windows(p)
#' p <- build_features(p)
#' resample_scheme(p, method = "spatial_block", k = 3)
#' @export
resample_scheme <- function(p, method = c("spatial_block",
                                          "leave_location_out",
                                          "forward_season", "random"),
                            k = 5, buffer = 0) {
    method <- match.arg(method)
    f <- p$features
    if (is.null(f)) stop("build features first with build_features().",
                         call. = FALSE)
    u <- units_of(p)
    coords <- u[match(f$unit_id, u$unit_id), c("x", "y"), drop = FALSE]
    geo <- isTRUE(p$config$geographic)
    n <- nrow(f)

    if (method == "random") {
        warning("random folds ignore spatial structure and usually overstate ",
                "skill; see ?resample_scheme.", call. = FALSE)
    }

    blocks <- switch(
        method,
        random = ((sample.int(n) - 1L) %% k) + 1L,
        leave_location_out = {
            uu <- unique(f$unit_id)
            bu <- ((match(uu, uu) - 1L) %% min(k, length(uu))) + 1L
            bu[match(f$unit_id, uu)]
        },
        forward_season = {
            ss <- sort(unique(f$season_id))
            match(f$season_id, ss)
        },
        spatial_block = {
            uu <- unique(f$unit_id)
            cu <- u[match(uu, u$unit_id), c("x", "y"), drop = FALSE]
            kk <- min(k, nrow(cu))
            if (kk < 2L) {
                stop("need at least two units for spatial blocking.",
                     call. = FALSE)
            }
            cs <- scale(as.matrix(cu))
            ## Lloyd rather than the default Hartigan-Wong: trial layouts are
            ## often on a regular grid, whose exact ties make Hartigan-Wong
            ## oscillate and fail to converge.
            cl <- stats::kmeans(cs, centers = kk, nstart = 25,
                                iter.max = 100L, algorithm = "Lloyd")$cluster
            cl[match(f$unit_id, uu)]
        })

    folds <- list()
    if (method == "forward_season") {
        ns <- max(blocks)
        if (ns < 2L) {
            stop("forward_season needs at least two seasons.", call. = FALSE)
        }
        for (i in seq_len(ns - 1L)) {
            folds[[i]] <- list(train = which(blocks <= i),
                               test = which(blocks == i + 1L))
        }
    } else {
        for (b in sort(unique(blocks))) {
            test <- which(blocks == b)
            train <- which(blocks != b)
            if (buffer > 0) {
                tc <- unique(coords[test, , drop = FALSE])
                keep <- vapply(train, function(j) {
                    all(.dist_km(coords$x[j], coords$y[j], tc$x, tc$y,
                                 geo) > buffer)
                }, TRUE)
                train <- train[keep]
            }
            if (length(train) < 2L || !length(test)) next
            folds[[length(folds) + 1L]] <- list(train = train, test = test)
        }
    }
    if (!length(folds)) {
        stop("the resampling scheme produced no usable folds; ",
             "reduce `buffer` or `k`.", call. = FALSE)
    }

    ## coordinates travel with the scheme so that it can be mapped without
    ## needing the project back
    structure(list(method = method, k = length(folds), buffer = buffer,
                   folds = folds, n = n, coords = coords,
                   unit_id = f$unit_id, season_id = f$season_id,
                   geographic = geo),
              class = "agri_resample")
}

#' @export
print.agri_resample <- function(x, ...) {
    cat("<agri_resample>\n")
    cat("  method :", x$method, "\n")
    cat("  folds  :", x$k, "\n")
    if (x$buffer > 0) cat("  buffer :", x$buffer, "\n")
    sz <- vapply(x$folds, function(f) length(f$test), 1L)
    cat("  test n :", paste(sz, collapse = ", "), "\n")
    invisible(x)
}
