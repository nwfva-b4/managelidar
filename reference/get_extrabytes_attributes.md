# Get the extrabytes attributes stored in LASfiles

`get_extrabytes_attributes()` extracts the names of extrabytes
attributes stored in LASfiles.

## Usage

``` r
get_extrabytes_attributes(path, full.names = FALSE)
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

  Filename of the LASfile.

- extrabytes_attributes:

  list of attribute names

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")

folder |> get_extrabytes_attributes()
#>                            filename extrabytes_attributes
#> 1 3dm_32_547_5724_1_ni_20240327.laz          Amplitud....
#> 2 3dm_32_547_5725_1_ni_20240327.laz          Amplitud....
#> 3 3dm_32_548_5724_1_ni_20240327.laz          Amplitud....
#> 4 3dm_32_548_5725_1_ni_20230904.laz          Amplitud....
#> 5 3dm_32_548_5725_1_ni_20240327.laz          Amplitud....
```
