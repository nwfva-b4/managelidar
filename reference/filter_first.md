# Filter to first acquisition from multi-temporal tiles

Identifies tiles with multiple acquisitions and returns only the first
(earliest) acquisition for each tile as a filtered VPC.

## Usage

``` r
filter_first(
  path,
  entire_tiles = TRUE,
  tolerance = 1,
  multitemporal_only = FALSE,
  verbose = TRUE
)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- entire_tiles:

  Logical. If `TRUE` (default), only considers tiles where the entire
  tile area has multi-temporal coverage. If `FALSE`, includes tiles with
  partial multi-temporal coverage.

- tolerance:

  Numeric. Tolerance in coordinate units for snapping extents to grid
  (default: 1, submeter inaccuracies are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

- multitemporal_only:

  Logical. If `TRUE`, only returns tiles with multiple acquisitions. If
  `FALSE` (default), includes all tiles.

- verbose:

  Logical. If TRUE (default), prints information about filtering
  results.

## Value

A VPC object (list) containing only the first acquisition for each tile.
Returns NULL invisibly if no features match the filter.

## Details

The function performs the following steps:

1.  Resolves input paths to a VPC object

2.  Analyzes tiles for multi-temporal coverage

3.  Groups tiles by location and selects the earliest acquisition for
    each

4.  Returns a filtered VPC object

## See also

[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md),
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md),
[`filter_multitemporal`](https://wiesehahn.github.io/managelidar/reference/filter_multitemporal.md),
[`resolve_vpc`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md)

## Examples

``` r
f <- system.file("extdata", package = "managelidar")

# get first acquisition per tile (entire tiles only, with 10m tolerance)
vpc <- filter_first(f, tolerance = 10)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
