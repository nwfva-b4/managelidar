# Filter point cloud files by spatial extent

Filter point cloud files by spatial extent

## Usage

``` r
filter_spatial(path, extent, crs = NULL, out_file = NULL)
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

- out_file:

  Optional. Path where the filtered VPC should be saved. If NULL
  (default), returns the VPC as an R object. If provided, saves to file
  and returns the file path. Must have `.vpc` extension and must not
  already exist. File is only created if filtering returns results.

## Value

If `out_file` is NULL, returns a VPC object (list) containing only
features that intersect the extent. If `out_file` is provided and
results exist, returns the path to the saved `.vpc` file. Returns NULL
invisibly if no features match the filter.

## Examples

``` r
# Example using the package's extdata folder
f <- system.file("extdata", package = "managelidar")
filter_spatial(f, c(547700, 5724010))
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
