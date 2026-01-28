# Get the Coordinate Reference System (CRS) of LAS files

`get_crs()` efficiently extracts and returns the coordinate reference
system (EPSG code) of LAS files.

## Usage

``` r
get_crs(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing LAS
  files, or a Virtual Point Cloud (.vpc) referencing LAS files.

- full.names:

  Logical. If `TRUE`, the returned filenames will be full paths; if
  `FALSE` (default), only base filenames are used.

## Value

A `data.frame` with two columns:

- filename:

  The filename or full path of each LAS file.

- crs:

  The EPSG code of the file's coordinate reference system.

## Details

This function efficiently reads the Coordinate Reference System of LAS
files from VPC. It is suitable for quickly inspecting the CRS of
multiple LAS/LAZ/COPC files.

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
get_crs(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
