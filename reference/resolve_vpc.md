# Resolve input paths to a single deduplicated VPC

Takes a mix of LAS/LAZ/COPC files, `.vpc` files, and VPC objects already
loaded in R, merges them if needed, deduplicates tiles (based on storage
location), and returns a VPC object or file path.

## Usage

``` r
resolve_vpc(paths, out_file = NULL)
```

## Arguments

- paths:

  Character vector of input paths, or a list containing VPC objects. Can
  be a mix of file paths (strings) and VPC objects (lists with
  type="FeatureCollection").

- out_file:

  Optional. Path where the VPC should be saved. If NULL (default),
  returns the VPC as an R object. If provided, saves to file and returns
  the file path.

## Value

If `out_file` is NULL, returns a list containing the VPC structure. If
`out_file` is provided, returns the path to the saved `.vpc` file.
