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

# AgriFusionR itself imports only base packages, so nothing here is required to
# install it. These are the optional learners and data clients that make the
# image useful out of the box. mgcv ships with R and is not installed again.
RUN Rscript -e 'install.packages(c("ranger", "xgboost", "Cubist", "glmnet", \
      "kernlab", "treeshap", "nasapower", "chirps", "daymetr", "agridat"), \
      repos = "https://cloud.r-project.org")' \
    && Rscript -e 'for (p in c("ranger","xgboost","Cubist","glmnet","kernlab", \
         "treeshap","nasapower","chirps","daymetr","agridat","mgcv")) \
         stopifnot(requireNamespace(p, quietly = TRUE))'

# Deliberately omitted: terra and geodata, and so the worldclim, soilgrids and
# elevation sources. They need GDAL, GEOS and PROJ, which would add several
# gigabytes. To include them, base this image on rocker/geospatial:4.5.2 and add
# terra and geodata to the install above; everything else works unchanged.

COPY . /build/AgriFusionR
RUN R CMD INSTALL --clean /build/AgriFusionR && rm -rf /build

# Fail the build early if the pipeline cannot run end to end.
RUN Rscript -e 'library(AgriFusionR); \
      p <- agri_project(demo_agri_data(n_units = 16, n_seasons = 3)); \
      p <- build_features(phenology_windows(add_climate(p)), stats = "sum"); \
      m <- train_model(p, "yield", algorithm = "ranger", k = 4); \
      stopifnot(is.finite(m$metrics[["rmse"]]), \
                !is.null(m$metrics_random), \
                nrow(explain(m, n_perm = 2)) > 0, \
                is.finite(uncertainty(m)$half_width)); \
      cat("AgriFusionR installed; pipeline runs end to end\n")'

WORKDIR /work
CMD ["R"]
