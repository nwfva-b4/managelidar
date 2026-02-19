# Get the Coordinate Reference System (CRS) of LASfiles

`get_crs()` efficiently extracts and returns the coordinate reference
system (EPSG code) of LASfiles.

## Usage

``` r
get_crs(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing
  LASfiles, or a Virtual Point Cloud (.vpc) referencing LASfiles.

- full.names:

  Logical. If `TRUE`, the returned filenames will be full paths; if
  `FALSE` (default), only base filenames are used.

## Value

A `data.frame` with two columns:

- filename:

  The filename or full path of each LASfile.

- crs:

  The EPSG code of the file's coordinate reference system.

## Details

This function efficiently reads the Coordinate Reference System of
LASfiles from VPC. It is suitable for quickly inspecting the CRS of
multiple LAS/LAZ/COPC files.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_crs()
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
