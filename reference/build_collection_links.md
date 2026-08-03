# Build links for a collection

Note: does not include an `items` link pointing at the items directory.
That convention is for a live OGC API - Features endpoint that returns a
`FeatureCollection` on request; a static file server just exposes the
raw directory, which STAC clients can't use. Static catalogs instead
list each item individually via `rel: "item"` links - see
[`rebuild_item_links()`](https://wiesehahn.github.io/managelidar/reference/rebuild_item_links.md),
called from
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md).

## Usage

``` r
build_collection_links(collection_dir, parent_path, title, parent_obj = NULL)
```

## Arguments

- collection_dir:

  Path to collection directory

- parent_path:

  Path to parent STAC file

- title:

  Title of this collection (used on its own `self` link)

- parent_obj:

  The parent object, if the caller already read it - avoids reading
  `parent_path` a second time. Read from `parent_path` if not supplied.

## Value

List of link objects
