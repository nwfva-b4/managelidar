# Recompute and register a collection's combined VPC asset

Writes `{collection_dir}/assets/collection.vpc` and registers it under
`collection_obj$assets$vpc`. Since this is derived from the items
themselves (not user-supplied), it's meant to be called automatically
whenever items change (see
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)).

## Usage

``` r
update_vpc_asset(collection_obj, collection_dir, items_dir)
```

## Arguments

- collection_obj:

  Collection object (list); `$assets` is updated

- collection_dir:

  Path to collection directory

- items_dir:

  Path to items directory

## Value

List with `collection_obj` (updated) and `vpc` (the combined VPC object,
for reuse by
[`update_footprints_asset()`](https://wiesehahn.github.io/managelidar/reference/update_footprints_asset.md)
without re-reading every item file a second time)
