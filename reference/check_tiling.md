# Check if tiles are valid (correct size and aligned to grid)

Check if tiles are valid (correct size and aligned to grid)

## Usage

``` r
check_tiling(path, tilesize = 1000, full.names = FALSE, tolerance = 1)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing
  LASfiles, or a Virtual Point Cloud (.vpc) referencing LASfiles.

- tilesize:

  Numeric. Expected tile size in units (default: 1000)

- full.names:

  Logical. Whether to return full file paths (default: FALSE)

- tolerance:

  Numeric. Tolerance in coordinate units for snapping extents to grid
  (default: 1, submeter inaccuaries are ignored). If \> 0, coordinates
  within this distance of a grid line will be snapped before processing.
  Set to 0 to disable snapping.

## Value

A data.frame with columns:

- filename:

  Name of the file

- size_ok:

  Logical indicating if tile has correct dimensions

- grid_ok:

  Logical indicating if tile is aligned to grid

- valid:

  Logical indicating if tile is both correct size and aligned

## Details

When `tolerance > 0`, coordinates within that distance of a grid line
will be snapped to that grid line before validation. This helps handle
minor floating point inaccuracies or small coordinate errors while
preserving coordinates that are genuinely misaligned.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

# check tiling scheme with 10m tolerance
las_files |> check_tiling(tolerance = 10)
#>                            filename size_ok grid_ok valid
#> 1 3dm_32_547_5724_1_ni_20240327.laz   FALSE   FALSE FALSE
#> 2 3dm_32_547_5725_1_ni_20240327.laz   FALSE   FALSE FALSE
#> 3 3dm_32_548_5724_1_ni_20240327.laz    TRUE    TRUE  TRUE
#> 4 3dm_32_548_5725_1_ni_20240327.laz    TRUE    TRUE  TRUE
```
