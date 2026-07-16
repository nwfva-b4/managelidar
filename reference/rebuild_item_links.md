# Rebuild a collection's `item` links from the files present in items_dir

Static STAC catalogs list each item directly on the collection via
`rel: "item"` links (the item-level equivalent of `rel: "child"` for
sub-collections). This re-derives that set from the items actually on
disk, so it stays correct across repeated
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
calls (including ones using `overwrite_items`) without accumulating
stale or duplicate entries.

## Usage

``` r
rebuild_item_links(links, collection_dir, items_dir)
```

## Arguments

- links:

  Existing links list; non-`item` links are preserved as-is

- collection_dir:

  Path to collection directory

- items_dir:

  Path to items directory

## Value

Updated links list
