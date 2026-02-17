# Get the LAS version of point cloud files

`get_lasversion()` extracts the LAS specification version (Major.Minor)
from the file headers of LAS/LAZ/COPC files.

## Usage

``` r
get_lasversion(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path(s) to LAS/LAZ/COPC files, a directory containing such
  files, or a Virtual Point Cloud (.vpc) referencing these files.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; otherwise
  base filenames (default).

## Value

A `data.frame` with columns:

- filename:

  Filename of the LAS file.

- lasversion:

  LAS version in `Major.Minor` format.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_lasversion()
#>                            filename lasversion
#> 1 3dm_32_547_5724_1_ni_20240327.laz        1.4
#> 2 3dm_32_547_5725_1_ni_20240327.laz        1.4
#> 3 3dm_32_548_5724_1_ni_20240327.laz        1.4
#> 4 3dm_32_548_5725_1_ni_20240327.laz        1.4
```
