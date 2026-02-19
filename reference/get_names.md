# Get LASfile names

`get_names()` returns the filenames of all LAS-related point cloud files
(`.las`, `.laz`, `.copc`) found in a given input.

## Usage

``` r
get_names(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path(s) to a LAS/LAZ/COPC file, a directory containing such
  files, or a Virtual Point Cloud (`.vpc`).

- full.names:

  Logical. If `TRUE`, return full file paths; otherwise return base
  filenames only (default).

## Value

A character vector of filenames or file paths.

## Details

The input may be a single file, a directory containing LASfiles, or a
Virtual Point Cloud (`.vpc`) referencing LAS/LAZ/COPC files. Internally,
file paths are resolved using
[`resolve_las_paths()`](https://wiesehahn.github.io/managelidar/reference/resolve_las_paths.md).

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_names()
#> [1] "3dm_32_547_5724_1_ni_20240327.laz" "3dm_32_547_5725_1_ni_20240327.laz"
#> [3] "3dm_32_548_5724_1_ni_20240327.laz" "3dm_32_548_5725_1_ni_20240327.laz"
```
