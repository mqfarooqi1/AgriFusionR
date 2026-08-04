## Assisted-by: Claude (Anthropic). Written with AI assistance under the
## author's direction; methods are established techniques cited in the
## documentation, and the results are validated in tests/testthat.

## Every operation appends to a ledger. This is what makes a re-run twelve
## months later mean something, and it is what report() turns into a methods
## section.

#' @keywords internal
#' @noRd
.prov_new <- function() {
    data.frame(step = character(), time = as.POSIXct(character()),
               detail = character(), stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
prov_add <- function(p, step, detail = "") {
    p$provenance <- rbind(
        p$provenance,
        data.frame(step = step, time = Sys.time(), detail = detail,
                   stringsAsFactors = FALSE))
    p
}

#' @rdname units_of
#' @export
provenance <- function(p) {
    if (inherits(p, "agri_model")) return(p$provenance)
    p$provenance
}
