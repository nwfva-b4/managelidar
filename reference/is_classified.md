# Check whether LAS files are classified

`is_classified()` determines whether LAS point cloud files contain point
classifications other than class `0` (unclassified).

## Usage

``` r
is_classified(path, full.names = FALSE, add_classes = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing such
  files, or a Virtual Point Cloud (`.vpc`).

- full.names:

  Logical. If `TRUE`, return full file paths; otherwise return base
  filenames only (default).

- add_classes:

  Logical. If `TRUE`, include a list-column with the detected
  classification codes present in the sampled points.

## Value

A `data.frame` with columns:

- file:

  Filename of the LAS file.

- classified:

  Logical indicating whether classified points (class \> 0) are present.

- classes:

  (Optional) List column of detected class codes.

## Details

Unlike header-based functions, this function reads actual point data. To
reduce I/O overhead, only a *subset* of points is sampled:

- For LAS/LAZ files, points are sampled from a small circular region
  around the spatial center of the file.

- For COPC files, only the first hierarchy level is read.

As a result, classification status is inferred from the sampled points
and may not reflect the full contents of the file.

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
is_classified(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
is_classified(f, add_classes = TRUE)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
