# Propagate a new extent up the STAC tree

Walks up the chain of `parent` links starting from `collection_path`,
updating each ancestor collection's extent to account for the new items
just added lower in the tree. Stops once it reaches a Catalog (which has
no `extent` field) or runs out of `parent` links.

## Usage

``` r
propagate_extent_to_ancestors(collection_path, spatial_extent, temporal_extent)
```

## Arguments

- collection_path:

  Path to the collection whose ancestors should be updated (typically
  the collection items were just added to).

- spatial_extent:

  Spatial extent of the newly added items (list format, as returned by
  [`extract_spatial_extent()`](https://wiesehahn.github.io/managelidar/reference/extract_spatial_extent.md)).

- temporal_extent:

  Temporal extent of the newly added items (list format, as returned by
  [`extract_temporal_extent()`](https://wiesehahn.github.io/managelidar/reference/extract_temporal_extent.md)).

## Value

Invisible NULL
