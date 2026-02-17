# Get the spatial extent of LAS files

`get_extent()` extracts the spatial extent (xmin, xmax, ymin, ymax) from
LASfiles.

## Usage

``` r
get_extent(path, as_sf = FALSE, full.names = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual
  Point Cloud (.vpc) referencing these files.

- as_sf:

  Logical. If `TRUE`, returns an `sf` object with geometry.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; otherwise
  base filenames (default).

## Value

A `data.frame` or `sf` object with columns:

- filename:

  Filename of the LAS file.

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

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
las_files |> get_extent()
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
