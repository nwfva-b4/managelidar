# Merge multiple Virtual Point Cloud (VPC) files

`merge_vpcs()` reads one or more `.vpc` files, merges their features,
and removes duplicate tiles (based on storage location). Optionally, the
merged VPC can be written to a file.

## Usage

``` r
merge_vpcs(vpc_files, out_file = NULL, overwrite = FALSE)
```

## Arguments

- vpc_files:

  Character. Paths to one or more `.vpc` files.

- out_file:

  Optional. Path to write the merged `.vpc` file. If `NULL`, a temporary
  file is created.

- overwrite:

  Logical. If `TRUE`, overwrite the output file if it exists.

## Value

A list representing the merged VPC (STAC FeatureCollection). Invisibly
returns the merged VPC. If `out_file` is provided, the file is written
as a valid `.vpc` JSON.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = TRUE, pattern = "[.]laz$")

# create two separate VPC files to merge
vpc_file1 <- tempfile(fileext = ".vpc")
vpc_file2 <- tempfile(fileext = ".vpc")
invisible(lasR::exec(lasR::write_vpc(vpc_file1, absolute_path = TRUE), on = las_files[1:2]))
invisible(lasR::exec(lasR::write_vpc(vpc_file2, absolute_path = TRUE), on = las_files[3:5]))

merged <- merge_vpcs(c(vpc_file1, vpc_file2))
```
