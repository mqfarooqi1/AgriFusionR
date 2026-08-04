## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

#' AgriFusionR: an integration framework for agricultural analytics
#'
#' R is already well supplied with machine learning, geospatial and
#' agronomic packages. What it lacks is the layer that joins them: a single
#' object that holds a management unit and its season, keeps climate, soil and
#' remote-sensing covariates aligned to it, aggregates them over the crop's
#' phenology rather than the calendar, and validates the result in a way that
#' survives spatial autocorrelation. That layer is what this package provides.
#'
#' @section Getting started:
#' [agri_project()] builds the object; [add_climate()] and its siblings attach
#' covariates; [phenology_windows()] derives thermal-time stages;
#' [build_features()] reduces everything to one row per unit and season;
#' [check_project()] looks for leakage and other faults; [train_model()] fits
#' and validates; [explain()], [uncertainty()] and [report()] interpret.
#'
#' @section Extending it:
#' [register_source()] and [register_learner()] add data providers and
#' algorithms without modifying the package.
#'
#' @keywords internal
"_PACKAGE"
