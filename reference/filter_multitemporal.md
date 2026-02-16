# Filter to multi-temporal tiles

Identifies and filters tiles that have been observed multiple times
(multi-temporal coverage), returning a VPC with only those tiles.

## Usage

``` r
filter_multitemporal(path, entire_tiles = TRUE, tolerance = 1)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- entire_tiles:

  Logical. If TRUE, only considers tiles that are exactly 1000x1000 m
  and aligned to a 1000m grid (default: TRUE)

- tolerance:

  Numeric. Tolerance in coordinate units for snapping extents to grid
  (default: 1, submeter inaccuracies are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

## Value

A VPC object (list) containing only tiles with multiple temporal
observations. Returns NULL invisibly if no multi-temporal tiles are
found.

## Details

This function identifies tiles that have been observed multiple times
(multi-temporal coverage). It reads extent and date information from a
VPC (Virtual Point Cloud) file, optionally snaps coordinates to a
regular grid, and groups observations by spatial extent.

When `entire_tiles = TRUE`, only tiles that are exactly 1000x1000 m and
aligned to a 1000 m grid are included in the analysis.

When `tolerance > 0`, coordinates within that distance of a grid line
are snapped to handle minor floating point inaccuracies.

**Important:** The returned VPC contains *all* observations for
multi-temporal tiles, meaning multiple files may reference the same
spatial tile. This is typically not suitable for direct processing in
most workflows in lasR, as data will be processed together. E.g.
creating a Canopy Height Model based on multi-temporal VPCs will result
in a single CHM raster based on lidar data from all acquisitions instead
of a separate CHM raster for each acquisition time.

Usually you want to use
[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md)
or
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md)
instead.

This intermediate filtering step might be useful when you need to:

- Identify which tiles have multi-temporal data before selecting a time
  period

- Explicitly want to work with combined multi-temporal data

## See also

[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md),
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md),
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md),
[`resolve_vpc`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md),
[`is_multitemporal`](https://wiesehahn.github.io/managelidar/reference/is_multitemporal.md)

## Examples

``` r
f <- system.file("extdata", package = "managelidar")

# Identify multi-temporal tiles
vpc_multi <- filter_multitemporal(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’


# Or chain filters for specific workflows:
vpc <- f |>
  filter_multitemporal() |>
  filter_temporal("2024") |>
  filter_latest()
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
