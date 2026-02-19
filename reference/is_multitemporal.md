# Check for multi-temporal coverage in LAS/LAZ files

Analyzes tiles for multi-temporal coverage. Returns a data frame with
tile information including whether each tile has multiple observations
and how many.

## Usage

``` r
is_multitemporal(
  path,
  entire_tiles = TRUE,
  tolerance = 1,
  full.names = FALSE,
  multitemporal_only = FALSE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing
  LASfiles, or a Virtual Point Cloud (.vpc) referencing LASfiles.

- entire_tiles:

  Logical. If TRUE, only considers tiles that are exactly 1000x1000 m
  and aligned to a 1000m grid (default: TRUE)

- tolerance:

  Numeric. Tolerance in coordinate units for snapping extents to grid
  (default: 1, submeter inaccuaries are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

- full.names:

  Logical. Whether to return full file paths (default: FALSE)

- multitemporal_only:

  Logical. If TRUE, only returns tiles with multiple observations
  (default: FALSE)

## Value

A data.frame with columns:

- filename:

  Name or path of the file

- tile:

  Tile identifier (xmin_ymin in km)

- date:

  Date of observation

- multitemporal:

  Logical indicating if tile has multiple observations

- observations:

  Number of observations for this tile

## Details

This function identifies tiles that have been observed multiple times
(multi-temporal coverage). It reads extent and date information from a
VPC (Virtual Point Cloud) file, optionally snaps coordinates to a
regular grid, and groups observations by spatial extent.

When `entire_tiles = TRUE`, only tiles that are 1000x1000 m and aligned
to a 1000 m grid are included in the analysis.

When `tolerance > 0`, coordinates within that distance of a grid line
are snapped to handle minor inaccuracies.

## See also

[`filter_multitemporal`](https://wiesehahn.github.io/managelidar/reference/filter_multitemporal.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*.laz")

las_files |> is_multitemporal(tolerance = 10)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
