## An adapter that runs but predicts nonsense is worse than one that errors,
## because nothing downstream will notice. Each learner is therefore checked on
## a problem where the right answer is known and every method listed should
## succeed: a linear signal in three predictors with modest noise.

fixture <- function(n = 200) {
    set.seed(42)
    x <- data.frame(a = stats::rnorm(n), b = stats::rnorm(n),
                    c = stats::rnorm(n))
    y <- 2 * x$a - x$b + 0.3 * x$c + stats::rnorm(n, sd = 0.3)
    tr <- seq_len(round(0.7 * n))
    list(xtr = x[tr, ], ytr = y[tr], xte = x[-tr, ], yte = y[-tr])
}

## The registry is global mutable state, and other test files add fixtures to
## it, so this iterates over the learners the package itself ships rather than
## over whatever happens to be registered when it runs.
builtin_learners <- c("lm", "glm", "knn", "ranger", "xgboost", "cubist",
                      "enet", "svm", "gam", "stack")

test_that("the package ships every learner it claims to", {
    expect_true(all(builtin_learners %in% list_learners()$name))
})

test_that("every built-in learner recovers a signal it should recover", {
    f <- fixture()
    set.seed(9)
    for (nm in builtin_learners) {
        lr <- AgriFusionR:::.afr$learners[[nm]]
        if (!all(vapply(lr$requires, requireNamespace, TRUE, quietly = TRUE))) {
            next
        }
        args <- if (nm == "xgboost") list(nrounds = 60L) else list()
        fit <- do.call(lr$fit, c(list(f$xtr, f$ytr), args))
        pr <- lr$predict(fit, f$xte)

        expect_length(pr, nrow(f$xte))
        expect_true(all(is.finite(pr)), info = nm)
        ## held-out correlation with the truth: a broken adapter fails this
        expect_gt(stats::cor(pr, f$yte), 0.8, label = nm)
    }
})

test_that("learner predictions are aligned to the rows they were given", {
    ## a transposed or reordered adapter would still correlate well overall,
    ## so check that reordering the input reorders the output the same way
    f <- fixture(120)
    for (nm in intersect(c("lm", "knn", "ranger", "enet"), builtin_learners)) {
        lr <- AgriFusionR:::.afr$learners[[nm]]
        if (!all(vapply(lr$requires, requireNamespace, TRUE, quietly = TRUE))) {
            next
        }
        fit <- lr$fit(f$xtr, f$ytr)
        p1 <- lr$predict(fit, f$xte)
        o <- rev(seq_len(nrow(f$xte)))
        p2 <- lr$predict(fit, f$xte[o, , drop = FALSE])
        expect_equal(p1[o], p2, tolerance = 1e-8, info = nm)
    }
})

test_that("unavailable learners fail with an actionable message", {
    register_learner("needs_unicorn", fit = function(x, y, ...) 1,
                     predict = function(object, newx, ...) rep(1, nrow(newx)),
                     requires = "unicorn.pkg.that.is.absent")
    expect_error(AgriFusionR:::.get_learner("needs_unicorn"), "needs package")
})

test_that("the stacked ensemble weights its base learners", {
    skip_if_not_installed("ranger")
    skip_if_not_installed("glmnet")
    f <- fixture(160)
    set.seed(3)
    fit <- AgriFusionR:::.afr$learners[["stack"]]$fit(f$xtr, f$ytr)
    w <- fit$weights

    expect_equal(sum(w), 1, tolerance = 1e-6)
    expect_true(all(w >= 0))
    expect_gte(length(w), 2)
    pr <- AgriFusionR:::.afr$learners[["stack"]]$predict(fit, f$xte)
    expect_gt(stats::cor(pr, f$yte), 0.8)
})

test_that("stack_weights() reports from a fitted project model", {
    skip_if_not_installed("ranger")
    skip_if_not_installed("glmnet")
    p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
    p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
    set.seed(5)
    m <- train_model(p, "yield", algorithm = "stack", k = 3,
                     compare_random = FALSE)
    w <- stack_weights(m)
    expect_equal(sum(w), 1, tolerance = 1e-6)
    expect_true(all(names(w) %in% list_learners()$name))

    m2 <- train_model(p, "yield", algorithm = "lm", k = 3,
                      compare_random = FALSE)
    expect_error(stack_weights(m2), "algorithm = 'stack'")
})

test_that("learners run end to end through train_model", {
    p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
    p <- build_features(phenology_windows(add_climate(p)), stats = "sum")
    for (nm in c("lm", "glm", "knn", "gam")) {
        m <- train_model(p, "yield", algorithm = nm, k = 3,
                         compare_random = FALSE)
        expect_s3_class(m, "agri_model")
        expect_true(is.finite(m$metrics[["rmse"]]), info = nm)
    }
})

test_that("the stack's default base learners are all real names", {
    ## The default list once contained "glmnet", the package name, where the
    ## registered learner is called "enet". Filter() dropped it silently, so
    ## the ensemble ran without its strongest member and nothing said so.
    default_base <- eval(formals(AgriFusionR:::.stack_fit)$base)
    if (is.null(default_base)) {
        default_base <- c("ranger", "enet", "cubist", "knn")
    }
    expect_true(all(default_base %in% list_learners()$name))
})

test_that("an unregistered base learner is reported, not silently dropped", {
    skip_if_not_installed("ranger")
    f <- fixture(120)
    set.seed(4)
    expect_warning(
        AgriFusionR:::.stack_fit(f$xtr, f$ytr,
                                 base = c("lm", "knn", "not_a_learner")),
        "unregistered base learner")
})

test_that("the stack includes the elastic net when glmnet is available", {
    skip_if_not_installed("glmnet")
    skip_if_not_installed("ranger")
    f <- fixture(160)
    set.seed(6)
    fit <- AgriFusionR:::.stack_fit(f$xtr, f$ytr)
    expect_true("enet" %in% names(fit$weights))
})
