# Get the spatial extent of LASfiles

`get_spatial_extent()` extracts the spatial extent (xmin, xmax, ymin,
ymax) from LASfiles. Can return extent per file or the combined extent
of all files.

## Usage

``` r
get_spatial_extent(
  path,
  per_file = TRUE,
  full.names = FALSE,
  as_sf = FALSE,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual
  Point Cloud (.vpc) referencing these files.

- per_file:

  Logical. If `TRUE` (default), returns extent per file. If `FALSE`,
  returns combined extent of all files.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; otherwise
  base filenames (default). Only used when `per_file = TRUE`.

- as_sf:

  Logical. If `TRUE`, returns an `sf` object with geometry. If `FALSE`
  (default), returns a data.frame.

- verbose:

  Logical. If `TRUE` (default), prints extent information.

## Value

When `per_file = TRUE`: A `data.frame` or `sf` object with columns:

- filename:

  Filename of the LASfile.

- xmin:

  Minimum X coordinate.

- xmax:

  Maximum X coordinate.

- ymin:

  Minimum Y coordinate.

- ymax:

  Maximum Y coordinate.

- geometry:

  (optional) Polygon geometry if `as_sf = TRUE`.

When `per_file = FALSE`: A single-row data.frame or sf object with the
combined extent.

## See also

[`get_temporal_extent`](https://wiesehahn.github.io/managelidar/reference/get_temporal_extent.md),
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
las_files |> get_spatial_extent()
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
