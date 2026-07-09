# Check whether LASfiles are spatially indexed

`is_indexed()` whether LASfiles are spatially indexed (either via
external `.lax` file or internally)

## Usage

``` r
is_indexed(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path(s) to a LAS/LAZ/COPC file, a directory containing such
  files, or a Virtual Point Cloud (`.vpc`).

- full.names:

  Logical. If `TRUE`, return full file paths; otherwise return base
  filenames only (default).

## Value

A `data.frame` with columns:

- file:

  Filename of the LASfile.

- is_indexed:

  Logical indicating whether point cloud is spatially indexed

## Details

The input may be a single file, a directory containing LASfiles, or a
Virtual Point Cloud (`.vpc`) referencing LAS/LAZ/COPC files. Internally,
file paths are resolved using
[`resolve_las_paths()`](https://wiesehahn.github.io/managelidar/reference/resolve_las_paths.md).

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> is_indexed()
#>                            filename indexed
#> 1 3dm_32_547_5724_1_ni_20240327.laz    TRUE
#> 2 3dm_32_547_5725_1_ni_20240327.laz    TRUE
#> 3 3dm_32_548_5724_1_ni_20240327.laz    TRUE
#> 4 3dm_32_548_5725_1_ni_20240327.laz    TRUE
```
