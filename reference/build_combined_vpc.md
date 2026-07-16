# Build a combined VPC (Virtual Point Cloud) FeatureCollection from every item in a collection's items directory

[`vpc_to_stac_items()`](https://wiesehahn.github.io/managelidar/reference/vpc_to_stac_items.md)
builds each item by taking a VPC feature and adding STAC-specific fields
on top (`links`, `collection`). This reverses that: strips those two
fields back off, leaving the original VPC feature shape
(`type`/`stac_version`/`stac_extensions`/`id`/
`geometry`/`bbox`/`properties`/`assets`) - so the result is a valid VPC
representing every item currently in the collection.

## Usage

``` r
build_combined_vpc(items_dir)
```

## Arguments

- items_dir:

  Path to items directory

## Value

A list representing a VPC FeatureCollection
