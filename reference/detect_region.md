# Auto-detect region (German federal state) from tile centroids

Downloads (and caches for the session via
`options(managelidar.states_sf=)`) German federal state boundaries, then
intersects each tile's centroid against them to find its two-letter
state code.

## Usage

``` r
detect_region(ext, effective_crs)
```

## Arguments

- ext:

  data.frame with per-file spatial extent columns `xmin`/`xmax`/
  `ymin`/`ymax`, as returned by
  [`get_spatial_extent()`](https://wiesehahn.github.io/managelidar/reference/get_spatial_extent.md).

- effective_crs:

  Integer EPSG code the extent coordinates are expressed in.

## Value

Character vector of two-letter region codes (`"de"` where no state
matches).
