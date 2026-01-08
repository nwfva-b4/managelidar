# Get the Coordinate Reference System (CRS) of LAS files

`get_crs()` extracts the coordinate reference system (EPSG code) from
the headers of LAS/LAZ/COPC files. It works on individual files,
directories containing LAS files, or Virtual Point Cloud (.vpc) files
referencing LAS files.

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

This function reads only the LAS file headers using
[`get_header()`](https://wiesehahn.github.io/managelidar/reference/get_header.md),
which avoids loading the full point cloud into memory. It is suitable
for quickly inspecting the CRS of multiple LAS/LAZ/COPC files.

## Examples

``` r
f <- system.file("extdata", package="managelidar")
get_crs(f)
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
