# Recompute and register a collection's combined VPC asset

Writes `{collection_dir}/assets/collection.vpc` and registers it under
`collection_obj$assets$vpc`. Since this is derived from the items
themselves (not user-supplied), it's meant to be called automatically
whenever items change (see
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)).

## Usage

``` r
update_vpc_asset(
  collection_obj,
  collection_dir,
  items_dir,
  changed_ids = character()
)
```

## Arguments

- collection_obj:

  Collection object (list); `$assets` is updated

- collection_dir:

  Path to collection directory

- items_dir:

  Path to items directory

- changed_ids:

  Character vector of item IDs actually (re)written this call - passed
  through to
  [`build_combined_vpc()`](https://wiesehahn.github.io/managelidar/reference/build_combined_vpc.md)
  so only those items are re-parsed instead of the whole collection.
  Pass [`character()`](https://rdrr.io/r/base/character.html) (or omit)
  to force a full rescan.

## Value

List with `collection_obj` (updated) and `vpc` (the combined VPC object,
for reuse by
[`update_footprints_asset()`](https://wiesehahn.github.io/managelidar/reference/update_footprints_asset.md)
without re-reading every item file a second time)
