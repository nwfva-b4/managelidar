# Check if tiles are valid (correct size and aligned to grid)

Check if tiles are valid (correct size and aligned to grid)

## Usage

``` r
check_tiling(path, tilesize = 1000, full.names = FALSE, tolerance = 1)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing LAS
  files, or a Virtual Point Cloud (.vpc) referencing LAS files.

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
f <- system.file("extdata", package = "managelidar")
check_tiling(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
