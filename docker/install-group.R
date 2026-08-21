## Install a group of packages and prove they are usable, in one step.
##
## install.packages() only warns when a package fails, so a Docker layer that
## merely calls it succeeds even when nothing was installed. This turns that
## warning into a non-zero exit, and prints the compilation output of whichever
## package failed so the build log says why.

pkgs <- commandArgs(trailingOnly = TRUE)
if (!length(pkgs)) stop("no packages given")

todo <- pkgs[!vapply(pkgs, requireNamespace, TRUE, quietly = TRUE)]
if (length(todo)) {
    install.packages(todo, Ncpus = max(1L, parallel::detectCores()))
}

ok <- vapply(pkgs, requireNamespace, TRUE, quietly = TRUE)
if (any(!ok)) {
    stop("failed to install: ", paste(pkgs[!ok], collapse = ", "),
         call. = FALSE)
}
cat("installed:", paste(pkgs, collapse = ", "), "\n")
