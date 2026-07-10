# Execute lasR pipeline on catalog

Wrapper for [`lasR::exec()`](https://rdrr.io/pkg/lasR/man/exec.html)
that works seamlessly in VPC-pipelines and handles VPC objects.
Automatically writes VPC objects to temporary files as needed by lasR.

## Usage

``` r
run_pipeline(path, pipeline, ...)
```

## Arguments

- path:

  Character or list. Path(s) to LAS/LAZ/COPC files, a directory, a VPC
  file, or a VPC object already loaded in R.

- pipeline:

  A lasR pipeline object created with lasR functions.

- ...:

  Additional arguments passed to
  [`lasR::exec()`](https://rdrr.io/pkg/lasR/man/exec.html).

## Value

Result from [`lasR::exec()`](https://rdrr.io/pkg/lasR/man/exec.html),
typically a list with pipeline outputs.

## Details

This function enables pipeline-style workflows with lasR by:

- Accepting the data source as the first argument (pipe-friendly)

- Handling VPC objects directly (writes to temp file automatically)

- Working with any input type accepted by
  [`resolve_vpc()`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
folder |>
  filter_temporal("2024") |>
  run_pipeline(lasR::dsm())
#> Filter temporal extent
#>   ▼ 5 LASfiles (2023-09-05 to 2024-03-27)
#>   ▼ 4 LASfiles retained (2024-03-27)
#> class       : SpatRaster
#> size        : 1992, 1349, 1  (nrow, ncol, nlyr)
#> resolution  : 1, 1  (x, y)
#> extent      : 547647, 548996, 5724000, 5725992  (xmin, xmax, ymin, ymax)
#> coord. ref. : ETRS89 / UTM zone 32N (EPSG:25832)
#> source      : file225b55fd3d6f.tif
#> name        : max
```
