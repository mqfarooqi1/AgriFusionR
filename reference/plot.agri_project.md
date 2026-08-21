# Plot a project's management units

Draws the units in space, sized by how many seasons each was observed
in. Worth looking at before modelling: clustered units are the situation
that makes random cross-validation misleading, and it is easier to see
than to infer.

## Usage

``` r
# S3 method for class 'agri_project'
plot(x, ...)
```

## Arguments

- x:

  An
  [`agri_project()`](https://mqfarooqi1.github.io/AgriFusionR/reference/agri_project.md).

- ...:

  Passed to `plot`.

## Value

`x`, invisibly. Called for the plot.

## See also

[`plot.agri_resample()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot.agri_resample.md),
[`plot_map()`](https://mqfarooqi1.github.io/AgriFusionR/reference/plot_map.md)

## Examples

``` r
p <- agri_project(demo_agri_data(n_units = 20, n_seasons = 3))
plot(p)
```
