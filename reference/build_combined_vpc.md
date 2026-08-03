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
build_combined_vpc(items_dir, existing_vpc = NULL, changed_ids = NULL)
```

## Arguments

- items_dir:

  Path to items directory

- existing_vpc:

  The collection's current combined VPC object (as read from its
  `collection.vpc` asset), or `NULL` to force/require a full rescan.

- changed_ids:

  Character vector of item IDs that were actually (re)written this call
  (see
  [`write_items()`](https://wiesehahn.github.io/managelidar/reference/write_items.md));
  ignored if `existing_vpc` is `NULL`.

## Value

A list representing a VPC FeatureCollection

## Details

When `existing_vpc`/`changed_ids` are supplied, only the items in
`changed_ids` are actually re-read/re-parsed from disk; every other
feature is carried over from `existing_vpc` as-is (just checked for
existence, not re-parsed, so a file deleted outside the package is still
correctly dropped). This avoids re-parsing every item's JSON on every
call, which at collections of thousands of items would otherwise make
ingesting them in K batches cost O(n^2) total parsing work. Falls back
to a full rescan when there's no existing VPC (first build for a new
collection).
