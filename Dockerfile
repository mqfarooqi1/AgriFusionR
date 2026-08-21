# R with AgriFusionR and its learners preinstalled.
#
# Build:  docker build -t agrifusionr .
# Run:    docker run --rm -it ghcr.io/mqfarooqi1/agrifusionr
#
# The image is published to the GitHub Container Registry by
# .github/workflows/docker.yaml.
FROM rocker/r-ver:4.5.2

LABEL org.opencontainers.image.title="AgriFusionR"
LABEL org.opencontainers.image.description="R with AgriFusionR preinstalled: an integration framework for agricultural analytics, with phenology-aligned features, spatial cross-validation and conformal prediction intervals."
LABEL org.opencontainers.image.source="https://github.com/mqfarooqi1/AgriFusionR"
LABEL org.opencontainers.image.url="https://mqfarooqi1.github.io/AgriFusionR/"
LABEL org.opencontainers.image.licenses="MIT"

# AgriFusionR imports only base packages, so none of this is needed to install
# it. These are the optional learners and the one data client that carries no
# geospatial dependencies. mgcv ships with R and is not installed again.
#
# No repos= is set on purpose: rocker images come preconfigured with a binary
# repository, and overriding it with cloud.r-project.org would force source
# compilation of ranger, xgboost, glmnet, kernlab and treeshap.
RUN Rscript -e 'install.packages(c("ranger", "xgboost", "Cubist", "glmnet", "kernlab", "treeshap", "nasapower", "agridat"))'

# Verify each one landed, so a silent install failure cannot reach the registry.
RUN Rscript -e 'p <- c("ranger","xgboost","Cubist","glmnet","kernlab","treeshap","nasapower","agridat","mgcv"); ok <- vapply(p, requireNamespace, TRUE, quietly = TRUE); if (any(!ok)) stop("missing: ", paste(p[!ok], collapse=", ")); cat("all optional packages present\n")'

# Left out on purpose, with the reason:
#
#   terra, geodata  - need GDAL, GEOS and PROJ, several gigabytes of system
#                     libraries. Without them the worldclim, soilgrids and
#                     elevation sources are unavailable.
#   chirps, daymetr - these look like plain API clients but both import sf and
#                     terra, so they pull in the same stack.
#
# The nasapower source works here, and so does everything that does not fetch
# remote data. For the full set of sources, base this image on
# rocker/geospatial:4.5.2 and add terra, geodata, chirps and daymetr to the
# install above; nothing else needs to change.

COPY . /build/AgriFusionR
RUN R CMD INSTALL --clean /build/AgriFusionR && rm -rf /build

# Fail the build early if the pipeline cannot run end to end.
RUN Rscript -e 'library(AgriFusionR); p <- agri_project(demo_agri_data(n_units = 16, n_seasons = 3)); p <- build_features(phenology_windows(add_climate(p)), stats = "sum"); m <- train_model(p, "yield", algorithm = "ranger", k = 4); stopifnot(is.finite(m$metrics[["rmse"]]), !is.null(m$metrics_random), nrow(explain(m, n_perm = 2)) > 0, is.finite(uncertainty(m)$half_width)); cat("AgriFusionR installed; pipeline runs end to end\n")'

WORKDIR /work
CMD ["R"]
