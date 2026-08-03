# Convert a VPC features table into a plain list of per-feature objects

[`build_combined_vpc()`](https://wiesehahn.github.io/managelidar/reference/build_combined_vpc.md)'s
in-memory VPCs represent `features` as a plain list (one element per
item); the same combined VPC asset re-read from disk via
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
instead has `features` as a data.frame (yyjsonr's default for a uniform
JSON array of objects, the same representation used for
[`resolve_vpc()`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md)-produced
VPCs elsewhere in the package). This normalizes either shape to the
plain-list form so callers don't need to branch on it.

## Usage

``` r
vpc_features_as_list(features)
```

## Arguments

- features:

  Either shape of a VPC's `$features`

## Value

List of per-feature objects
