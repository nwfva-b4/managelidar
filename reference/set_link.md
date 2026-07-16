# Replace the link with a given `rel`, or add it if not present

For relation types that should only appear once per object (`root`,
`parent`, `self`, `icon`). Not suitable for `child`/`item` links, which
are multi-valued - see
[`add_child_link()`](https://wiesehahn.github.io/managelidar/reference/add_child_link.md)
and
[`rebuild_item_links()`](https://wiesehahn.github.io/managelidar/reference/rebuild_item_links.md)
for those.

## Usage

``` r
set_link(links, new_link)
```

## Arguments

- links:

  List of link objects

- new_link:

  The link object to set (its `rel` determines what gets replaced)

## Value

Updated links list

## Details

Replaces in place (at the existing link's position) rather than removing
and re-appending, so a call that doesn't actually change anything
doesn't reorder the links list either - that reordering would otherwise
make before/after equality checks (used to detect whether a write is
actually needed) report a change that isn't really there.
