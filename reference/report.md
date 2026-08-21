# Write a model card

Turns the provenance ledger and the validation results into a model card
in Markdown: what was fitted, on what data, validated how, with which
caveats.

## Usage

``` r
report(object, file = NULL, top = 10, ...)

# S3 method for class 'agri_model'
report(object, file = NULL, top = 10, ...)
```

## Arguments

- object:

  A model fitted by
  [`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md).

- file:

  Optional path to write to. The text is always returned.

- top:

  Number of features to list.

- ...:

  Ignored.

## Value

A character vector of Markdown lines, invisibly when written to file.

## Details

The limitations section is generated from the model's own diagnostics
rather than written by hand, so it cannot fall out of step with the
results. If random cross-validation would have overstated the model, the
card says so.

## See also

[`train_model()`](https://mqfarooqi1.github.io/AgriFusionR/reference/train_model.md),
[`provenance()`](https://mqfarooqi1.github.io/AgriFusionR/reference/units_of.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 12, n_seasons = 3))
p <- build_features(phenology_windows(add_climate(p)))
m <- train_model(p, "yield", algorithm = "lm", k = 3)
#> Warning: 64 features for 36 observations. Unregularised linear learners will be rank deficient here; prefer a tree-based or penalised learner, or pass fewer `stats` to build_features().
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
cat(head(report(m), 20), sep = "\n")
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> Warning: prediction from rank-deficient fit; attr(*, "non-estim") has doubtful cases
#> # Model card
#> 
#> Generated 2026-08-21 by AgriFusionR.
#> 
#> ## What was fitted
#> 
#> - Target: `yield`
#> - Learner: `lm`
#> - Observations: 36
#> - Features: 64
#> - Units: 12 over 3 season(s)
#> 
#> ## How it was validated
#> 
#> - Scheme: spatial_block, 3 folds
#> 
#> | Resampling | n | RMSE | MAE | R2 | Bias |
#> |---|---|---|---|---|---|
#> | spatial_block (reported) | 36 | 584.939 | 339.920 | -869544.922 | +336.637 |
#> | random (for comparison) | 36 | 21.961 | 10.544 | -1224.722 | +3.280 |
```
