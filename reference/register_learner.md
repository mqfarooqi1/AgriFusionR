# Register a learning algorithm

Adds an algorithm to the learner registry so that
[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md)
can select it by name. Keeping learners behind a registry is what allows
the package to delegate to established implementations rather than
reimplement them.

## Usage

``` r
register_learner(name, fit, predict, requires = character(), description = "")
```

## Arguments

- name:

  Name used to select the learner.

- fit:

  A function `function(x, y, ...)` returning a fitted model, where `x`
  is a numeric data frame of predictors and `y` a numeric response.

- predict:

  A function `function(object, newx, ...)` returning a numeric vector of
  predictions.

- requires:

  Character vector of packages the learner needs.

- description:

  A one-line human description.

## Value

Invisibly, the registered name.

## See also

[`list_learners()`](https://mqfarooqi1.github.io/AgriFusionR/reference/list_sources.md),
[`register_source()`](https://mqfarooqi1.github.io/AgriFusionR/reference/register_source.md)

## Examples

``` r
register_learner("mean_only",
                 fit = function(x, y, ...) mean(y),
                 predict = function(object, newx, ...) {
                     rep(object, nrow(newx))
                 })
"mean_only" %in% list_learners()$name
#> [1] TRUE
```
