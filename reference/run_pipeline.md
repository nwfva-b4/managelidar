# Execute lasR pipeline on catalog

Wrapper for `lasR::exec()` that works seamlessly in VPC-pipelines and
handles VPC objects. Automatically writes VPC objects to temporary files
as needed by lasR.

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

  Additional arguments passed to `lasR::exec()`.

## Value

Result from `lasR::exec()`, typically a list with pipeline outputs.

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
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
