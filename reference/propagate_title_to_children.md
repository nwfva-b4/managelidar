# Propagate a collection's title down to its immediate children

Item files store their owning collection's title inline, in the
`collection`/`parent` links baked in by
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md) -
since items are static files, not computed on read, renaming a
collection doesn't retroactively update items already written unless
something patches them. Direct child collections' own `parent` link
title is refreshed the same way.

## Usage

``` r
propagate_title_to_children(collection_dir, items_dir, new_title, child_links)
```

## Arguments

- collection_dir:

  Path to the collection whose title changed

- items_dir:

  That collection's items directory

- new_title:

  The collection's current (just-changed) title

- child_links:

  This collection's own `rel: "child"` links

## Value

Invisible NULL

## Details

This is deliberately single-level, unlike
[`propagate_extent_to_ancestors()`](https://wiesehahn.github.io/managelidar/reference/propagate_extent_to_ancestors.md)'s
unbounded walk: a grandchild item or collection references its
*immediate* parent's title, which didn't change here, so there's nothing
further to cascade.
