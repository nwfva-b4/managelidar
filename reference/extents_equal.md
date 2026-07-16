# Compare two extents by value, ignoring internal representation

An extent read from disk via
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
has its bbox/interval as a matrix; a freshly computed one (from
[`extract_spatial_extent()`](https://wiesehahn.github.io/managelidar/reference/extract_spatial_extent.md),
[`merge_spatial_extents()`](https://wiesehahn.github.io/managelidar/reference/merge_spatial_extents.md),
etc.) has them as a list. A plain
[`identical()`](https://rdrr.io/r/base/identical.html) on the two would
report "different" even when the actual coordinates/dates match, purely
due to representation - this compares the underlying values instead.

## Usage

``` r
extents_equal(extent1, extent2)
```

## Arguments

- extent1, extent2:

  Extent objects to compare

## Value

Logical
