# Build an empty placeholder extent for a newly created collection

Spatial bbox has no valid "unknown" representation in STAC (must be
numeric), so a zero bbox is used as a clearly-empty placeholder.
Temporal interval bounds may legally be `NULL` per the STAC spec,
meaning "unknown". Both are meant to be replaced (not merged) the first
time items are added via
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md).

## Usage

``` r
empty_extent()
```

## Value

List with placeholder spatial and temporal extent
