# Get the point cloud summary of LAS files

`get_summary` derives information for LAS files, such as number of
points per class and histogram distribution of z or intensity values.

## Usage

``` r
get_summary(path, full.names = FALSE)
```

## Arguments

- path:

  The path to a LAS file (.las/.laz/.copc), to a directory which
  contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS
  files.

- full.names:

  Whether to return the full file paths or just the filenames (default)
  Whether to return the full file path or just the file name (default).

## Value

A named list of summary information (`npoints`, `nsingle`, `nwithheld`,
`nsynthetic`, `npoints_per_return`, `npoints_per_class`, `z_histogram`,
`i_histogram`, `crs`, `epsg`)

## Details

The function needs to read the actual point cloud data! To speed up the
processing the function reads just a sample of points, which is slower
than just reading the header information but much faster than reading
the entire file. But the results are thus only valid for the subsample
of points and do not necessarily reflect the entire file.

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
get_summary(f)
#> Error in get_summary(f): could not find function "get_summary"
```
