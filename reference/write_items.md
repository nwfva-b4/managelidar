# Write STAC items to files, but only those that actually changed

Items already skipped by
[`vpc_to_stac_items()`](https://wiesehahn.github.io/managelidar/reference/vpc_to_stac_items.md)
(`skipped_existing`) are left alone. Of the rest, each is compared
against its on-disk version (if any) via
[`write_stac_if_changed()`](https://wiesehahn.github.io/managelidar/reference/write_stac_if_changed.md)
and only written - with a fresh `properties$updated` - if it actually
differs; an item identical to what's already on disk is left untouched,
`created`/`updated` included. This is what makes re-running
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
with `overwrite_items = TRUE` over unchanged input a true no-op.

## Usage

``` r
write_items(built)
```

## Arguments

- built:

  List as returned by
  [`vpc_to_stac_items()`](https://wiesehahn.github.io/managelidar/reference/vpc_to_stac_items.md)

## Value

Character vector of item IDs that were actually (re)written
