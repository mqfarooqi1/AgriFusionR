## Test environments

* local Windows 11, R 4.5.2
* GitHub Actions:
  * Ubuntu 24.04, R release / R devel / R oldrel-1
  * Windows Server 2022, R release
  * macOS 14, R release

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

The only other finding on the local machine is a warning that `qpdf` is not
installed there, which is a property of that machine rather than of the
package.

## Notes for the reviewer

`Imports` is deliberately limited to base packages (`graphics`, `grDevices`,
`stats`, `utils`). The `Suggests` list is long because the package is an
integration layer: each entry backs one optional data source or learning
algorithm reached through a registry, and none of them is required. The
package installs and its core functions work with none of the suggested
packages present.

No example or test accesses the network. The data-source adapters that need
internet are documented as such and are exercised only interactively. Tests
and vignette chunks that depend on a suggested package are guarded with
`skip_if_not_installed()` or an `eval` condition.
