# Filter point cloud files by spatial extent

Filter point cloud files by spatial extent

## Usage

``` r
filter_spatial(path, extent, crs = NULL, verbose = TRUE)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- extent:

  Spatial extent to filter by. Can be:

  - Numeric vector of length 2 (point: x, y) or 4 (bbox: xmin, ymin,
    xmax, ymax)

  - sf/sfc object (point, multipoint, polygon, bbox)

- crs:

  Character or numeric. Coordinate reference system of the extent. If
  NULL (default) and extent is numeric, assumes extent is in the same
  CRS as the VPC features. Required for sf objects without CRS. Can be
  EPSG code (e.g., 4326, 25832) or WKT2 string.

- verbose:

  Logical. If TRUE (default), prints information about filtering
  results.

## Value

A VPC object (list) containing only features that intersect the extent.
Returns NULL invisibly if no features match the filter.

## See also

[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md),
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md),
[`filter_temporal`](https://wiesehahn.github.io/managelidar/reference/filter_temporal.md),
[`filter_multitemporal`](https://wiesehahn.github.io/managelidar/reference/filter_multitemporal.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

vpc <- las_files |> filter_spatial(c(548700, 5725010))
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
