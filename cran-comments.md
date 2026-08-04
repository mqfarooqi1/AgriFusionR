## Test environments

* local Windows 11, R 4.5.2
* GitHub Actions: Ubuntu (release, devel, oldrel-1), Windows (release),
  macOS (release)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

The local check additionally reported a warning that `qpdf` is not installed
and a note about future file timestamps. Both are properties of the machine
the check ran on rather than of the package.

## Notes for the reviewer

The package deliberately keeps `Imports` to base packages only
(`graphics`, `grDevices`, `stats`, `utils`). Everything else is in `Suggests`
behind `requireNamespace()`, so the package installs and its core functions
work without any of them. The `Suggests` list is long because the package is
an integration layer: each entry backs one optional data source or learning
algorithm, reached through a registry, and none is required.

No example or test accesses the network. Data-source adapters that need
internet are documented as such and are exercised only interactively.
Tests that depend on a suggested package use `skip_if_not_installed()`.
