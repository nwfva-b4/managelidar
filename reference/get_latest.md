# Get latest acquisition from multi-temporal tiles

Identifies tiles with multiple acquisitions and returns only the latest
(newest) acquisition for each tile. Can return results as a data frame
or write a filtered VPC file.

## Usage

``` r
get_latest(
  path,
  entire_tiles = TRUE,
  tolerance = 1,
  full.names = FALSE,
  multitemporal_only = FALSE,
  out_file = NULL
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
  (default: 1, submeter inaccuaries are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

- full.names:

  Logical. Whether to return full file paths (default: FALSE)

- multitemporal_only:

  Logical. If `TRUE`, only returns tiles with multiple acquisitions. If
  `FALSE` (default), includes all tiles.

- out_file:

  Optional. Path where a filtered VPC file should be saved. If `NULL`
  (default), returns a data frame. If provided, writes a VPC file
  containing only the latest acquisitions and returns the file path.

## Value

If `out_file` is `NULL`, returns a data frame with columns:

- filename:

  Character. Path to the LAS/LAZ file

- date:

  Date. Acquisition date of the file

If `out_file` is provided, returns the path to the saved VPC file.

## Details

The function performs the following steps:

1.  Resolves input paths to a VPC object

2.  Checks for multi-temporal coverage using
    [`check_multitemporal`](https://wiesehahn.github.io/managelidar/reference/check_multitemporal.md)

3.  Groups tiles by location and selects the latest acquisition for each

4.  Returns either a summary data frame or writes a filtered VPC file

## See also

[`get_first`](https://wiesehahn.github.io/managelidar/reference/get_first.md),
[`check_multitemporal`](https://wiesehahn.github.io/managelidar/reference/check_multitemporal.md),
[`resolve_vpc`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md)

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
get_latest(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
