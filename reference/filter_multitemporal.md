# Filter tiles by number of temporal observations

Filters tiles based on the number of temporal observations, returning a
VPC with tiles that have a specific number of files or multiple
observations.

## Usage

``` r
filter_multitemporal(
  path,
  n = NULL,
  entire_tiles = TRUE,
  tolerance = 1,
  verbose = TRUE
)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- n:

  Numeric or NULL. Number of observations to filter by:

  - NULL (default): Returns all tiles with 2 or more observations
    (multi-temporal)

  - 1: Returns tiles with exactly 1 observation (mono-temporal)

  - 2, 3, etc.: Returns tiles with exactly that many observations

- entire_tiles:

  Logical. If TRUE (default), only considers tiles that are exactly
  1000x1000 m and aligned to a 1000m grid.

- tolerance:

  Numeric. Tolerance in coordinate units for snapping extents to grid
  (default: 1, submeter inaccuracies are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

- verbose:

  Logical. If TRUE (default), prints information about filtering
  results.

## Value

A VPC object (list) containing only tiles matching the temporal
criteria. Returns NULL invisibly if no matching tiles are found.

## Details

This function identifies tiles based on their temporal coverage. It
reads extent and date information from a VPC (Virtual Point Cloud) file,
optionally snaps coordinates to a regular grid, and groups observations
by spatial extent.

When `entire_tiles = TRUE`, only tiles that are exactly 1000x1000 m and
aligned to a 1000 m grid are included in the analysis.

When `tolerance > 0`, coordinates within that distance of a grid line
are snapped to handle minor floating point inaccuracies.

**When n = NULL (multi-temporal):**

The returned VPC contains *all* observations for multi-temporal tiles,
meaning multiple files may reference the same spatial tile. This is
typically not suitable for direct processing in most workflows in lasR,
as data will be processed together. E.g. creating a Canopy Height Model
based on multi-temporal VPCs will result in a single CHM raster based on
lidar data from all acquisitions instead of a separate CHM raster for
each acquisition time.

Usually you want to use
[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md)
or
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md)
instead.

This intermediate filtering step might be useful when you need to:

- Identify which tiles have multi-temporal data before selecting a time
  period

- Filter to tiles with exactly n observations for quality control

- Explicitly want to work with combined multi-temporal data

- Isolate mono-temporal tiles (n = 1) for separate processing

## See also

[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md),
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md),
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md),
[`resolve_vpc`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md),
[`is_multitemporal`](https://wiesehahn.github.io/managelidar/reference/is_multitemporal.md)

## Examples

``` r
f <- system.file("extdata", package = "managelidar")

# Get all multi-temporal (2+ observations) tiles (entire tiles only, with 10m tolerance)
vpc_multi <- filter_multitemporal(f, tolerance = 10)
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Get only mono-temporal (exactly 1 observation) tiles  (entire tiles only, with 10m tolerance)
vpc_mono <- filter_multitemporal(f, entire_tiles = FALSE, tolerance = 10, n = 1)
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Get tiles with exactly 3 observations (entire tiles only, with 10m tolerance)
vpc_three <- filter_multitemporal(f, n = 3)
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Chain filters for specific workflows:
vpc <- f |>
  filter_multitemporal(tolerance = 10) |>
  filter_temporal("2024") |>
  filter_latest(tolerance = 10)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
