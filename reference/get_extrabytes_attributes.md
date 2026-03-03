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
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

folder |> get_extrabytes_attributes()
#> # A tibble: 5 × 2
#>   filename                          extrabytes_attributes
#>   <chr>                             <list>               
#> 1 3dm_32_547_5724_1_ni_20240327.laz <chr [3]>            
#> 2 3dm_32_547_5725_1_ni_20240327.laz <chr [3]>            
#> 3 3dm_32_548_5724_1_ni_20240327.laz <chr [3]>            
#> 4 3dm_32_548_5725_1_ni_20230904.laz <chr [8]>            
#> 5 3dm_32_548_5725_1_ni_20240327.laz <chr [3]>            
```
