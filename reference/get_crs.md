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
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832
```
