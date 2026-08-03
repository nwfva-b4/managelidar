# Convert VPC features to STAC items

Builds a candidate STAC item per VPC feature. When an item file of the
same id already exists on disk and `overwrite = FALSE`, building is
skipped entirely for that feature (it would never be written anyway -
see
[`write_items()`](https://wiesehahn.github.io/managelidar/reference/write_items.md)).
`created`/`updated` are not stamped here; that happens in
[`write_items()`](https://wiesehahn.github.io/managelidar/reference/write_items.md)
via
[`write_stac_if_changed()`](https://wiesehahn.github.io/managelidar/reference/write_stac_if_changed.md),
which is also what decides whether an existing item actually changed.

## Usage

``` r
vpc_to_stac_items(
  vpc_obj,
  collection_dir,
  items_dir,
  root_path,
  collection_id,
  root_title,
  collection_title,
  overwrite = FALSE
)
```

## Arguments

- vpc_obj:

  VPC object (list with \$features)

- collection_dir:

  Path to collection directory

- items_dir:

  Path to items directory

- root_path:

  Absolute path to root catalog

- collection_id:

  Parent collection ID

- root_title:

  Title of the root catalog

- collection_title:

  Title of the owning collection

- overwrite:

  Logical. If `FALSE` (default), existing items are left untouched (not
  even read/compared). If `TRUE`, existing items are compared against
  the freshly built version and only rewritten if they actually changed.

## Value

List with one entry per feature: `item` (built item, or `NULL` if
skipped), `existing` (the on-disk item, or `NULL`), `path`, and
`skipped_existing` (logical).
