## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

## The registries are the extension mechanism for the whole package: a new
## data provider or algorithm is a function plus one registration call.

.afr <- new.env(parent = emptyenv())
.afr$sources <- list()
.afr$learners <- list()

#' Register a covariate source
#'
#' Adds a data provider to the source registry, making it available to
#' [add_climate()], [add_soil()] and [add_satellite()]. This is the extension
#' point for new providers: no change to the package is needed.
#'
#' @param name Name used to select the source, for example `"power"`.
#' @param fetch A function with signature `function(units, seasons, ...)`
#'   returning a data frame. Series sources must return one row per unit and
#'   date, with columns `unit_id` and `date`; static sources one row per unit,
#'   with column `unit_id`.
#' @param provides Character vector of the variables the source returns.
#' @param kind Either `"series"` for time-varying data or `"static"` for
#'   values fixed within a unit.
#' @param requires_network Whether the source needs internet access. Sources
#'   that do are skipped in tests and examples.
#' @param description A one-line human description.
#' @return Invisibly, the registered name.
#' @seealso [list_sources()], [register_learner()]
#' @examples
#' register_source("flat",
#'                 fetch = function(units, seasons, ...) {
#'                     data.frame(unit_id = units$unit_id, elevation = 100)
#'                 },
#'                 provides = "elevation", kind = "static",
#'                 requires_network = FALSE)
#' "flat" %in% list_sources()$name
#' @export
register_source <- function(name, fetch, provides,
                            kind = c("series", "static"),
                            requires_network = TRUE, description = "") {
    kind <- match.arg(kind)
    stopifnot(is.character(name), length(name) == 1L, nzchar(name))
    if (!is.function(fetch)) stop("`fetch` must be a function.", call. = FALSE)
    .afr$sources[[name]] <- list(
        name = name, fetch = fetch, provides = as.character(provides),
        kind = kind, requires_network = isTRUE(requires_network),
        description = description)
    invisible(name)
}

#' Register a learning algorithm
#'
#' Adds an algorithm to the learner registry so that [train_model()] can select
#' it by name. Keeping learners behind a registry is what allows the package to
#' delegate to established implementations rather than reimplement them.
#'
#' @param name Name used to select the learner.
#' @param fit A function `function(x, y, ...)` returning a fitted model, where
#'   `x` is a numeric data frame of predictors and `y` a numeric response.
#' @param predict A function `function(object, newx, ...)` returning a numeric
#'   vector of predictions.
#' @param requires Character vector of packages the learner needs.
#' @param description A one-line human description.
#' @return Invisibly, the registered name.
#' @seealso [list_learners()], [register_source()]
#' @examples
#' register_learner("mean_only",
#'                  fit = function(x, y, ...) mean(y),
#'                  predict = function(object, newx, ...) {
#'                      rep(object, nrow(newx))
#'                  })
#' "mean_only" %in% list_learners()$name
#' @export
register_learner <- function(name, fit, predict, requires = character(),
                             description = "") {
    stopifnot(is.character(name), length(name) == 1L, nzchar(name))
    if (!is.function(fit) || !is.function(predict)) {
        stop("`fit` and `predict` must both be functions.", call. = FALSE)
    }
    .afr$learners[[name]] <- list(name = name, fit = fit, predict = predict,
                                  requires = as.character(requires),
                                  description = description)
    invisible(name)
}

#' List registered sources and learners
#'
#' @return A data frame describing what is currently registered.
#' @seealso [register_source()], [register_learner()]
#' @examples
#' list_sources()
#' list_learners()
#' @export
list_sources <- function() {
    s <- .afr$sources
    if (!length(s)) {
        return(data.frame(name = character(), kind = character(),
                          provides = character(), network = logical(),
                          description = character()))
    }
    data.frame(
        name = vapply(s, `[[`, "", "name"),
        kind = vapply(s, `[[`, "", "kind"),
        provides = vapply(s, function(z) paste(z$provides, collapse = ", "), ""),
        network = vapply(s, `[[`, TRUE, "requires_network"),
        description = vapply(s, `[[`, "", "description"),
        row.names = NULL, stringsAsFactors = FALSE)
}

#' @rdname list_sources
#' @export
list_learners <- function() {
    s <- .afr$learners
    if (!length(s)) {
        return(data.frame(name = character(), requires = character(),
                          description = character()))
    }
    data.frame(
        name = vapply(s, `[[`, "", "name"),
        requires = vapply(s, function(z) paste(z$requires, collapse = ", "), ""),
        description = vapply(s, `[[`, "", "description"),
        row.names = NULL, stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
.get_source <- function(name) {
    s <- .afr$sources[[name]]
    if (is.null(s)) {
        stop("unknown source '", name, "'. Registered: ",
             paste(names(.afr$sources), collapse = ", "), call. = FALSE)
    }
    s
}

#' @keywords internal
#' @noRd
.get_learner <- function(name) {
    s <- .afr$learners[[name]]
    if (is.null(s)) {
        stop("unknown learner '", name, "'. Registered: ",
             paste(names(.afr$learners), collapse = ", "), call. = FALSE)
    }
    miss <- s$requires[!vapply(s$requires, .have_pkg, TRUE)]
    if (length(miss)) {
        stop("learner '", name, "' needs package(s): ",
             paste(miss, collapse = ", "), call. = FALSE)
    }
    s
}

#' @keywords internal
#' @noRd
.have_pkg <- function(p) requireNamespace(p, quietly = TRUE)
