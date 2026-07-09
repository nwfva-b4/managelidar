# Check whether LASfiles are classified

`is_classified()` determines whether LAS point cloud files contain point
classifications other than class `0` (unclassified).

## Usage

``` r
is_classified(
  path,
  samplebased = TRUE,
  full.names = FALSE,
  add_classes = FALSE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing such
  files, or a Virtual Point Cloud (`.vpc`).

- samplebased:

  Logical. If `TRUE` (default), reads only a spatial subsample of each
  file.

- full.names:

  Logical. If `TRUE`, return full file paths; otherwise return base
  filenames only (default).

- add_classes:

  Logical. If `TRUE`, include a list-column with the detected
  classification codes present in the sampled points.

## Value

A `data.frame` with columns:

- file:

  Filename of the LASfile.

- classified:

  Logical indicating whether classified points (class \> 0) are present.

- classes:

  (Optional) List column of detected class codes.

## Details

Unlike header-based functions, this function reads actual point data. To
reduce I/O overhead, only a *subset* of points is sampled:

- For LAS/LAZ files, points are sampled from a small circular region
  (10m radius) around the spatial center of the file.

- For COPC files, only the first two hierarchy levels (0,1) are read.

As a result, classification status is inferred from the sampled points
and may not reflect the full contents of the file. To determine if a
LASfile is classified this is usually sufficient, but to get class
abundances consider using
[`get_summary`](https://wiesehahn.github.io/managelidar/reference/get_summary.md).

## See also

[`get_summary`](https://wiesehahn.github.io/managelidar/reference/get_summary.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> is_classified(add_classes = TRUE)
#>                                 file classified classes
#>                               <char>     <lgcl>  <AsIs>
#> 1: 3dm_32_547_5724_1_ni_20240327.laz       TRUE       2
#> 2: 3dm_32_547_5725_1_ni_20240327.laz       TRUE       2
#> 3: 3dm_32_548_5724_1_ni_20240327.laz       TRUE      12
#> 4: 3dm_32_548_5725_1_ni_20240327.laz       TRUE      12
```
