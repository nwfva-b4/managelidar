# Create (or update) a STAC catalog

Creates a new root STAC catalog at the given path. This is the entry
point of a STAC tree; collections are added underneath it with
[`stac_add_collection()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection.md).

## Usage

``` r
stac_create_catalog(
  path,
  id,
  title = id,
  description = "STAC catalog",
  icon = NULL,
  copy = NULL
)
```

## Arguments

- path:

  Directory in which to create the catalog. `catalog.json` is written
  inside this directory.

- id:

  Catalog ID. Ignored (with a warning) if a catalog already exists at
  `path` with a different ID, since IDs aren't renamed here.

- title:

  Catalog title. Defaults to `id` for a new catalog; left unchanged on
  update unless explicitly passed.

- description:

  Catalog description. Defaults to `"STAC catalog"` for a new catalog;
  left unchanged on update unless explicitly passed.

- icon:

  A URL, or a path to a local image file, to set as the catalog's icon
  link (shown in headers/listings by STAC Browser and similar clients).
  See
  [`stac_set_icon()`](https://wiesehahn.github.io/managelidar/reference/stac_set_icon.md)
  for details.

- copy:

  Whether to copy `icon` into the catalog tree rather than reference it
  in place. See
  [`stac_set_icon()`](https://wiesehahn.github.io/managelidar/reference/stac_set_icon.md)
  for the default behavior.

## Value

Path to `catalog.json` (invisibly), for piping into
[`stac_add_collection()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection.md).

## Details

If a catalog already exists at `path`, it is updated in place instead of
being recreated: any argument you explicitly pass (`title`,
`description`, `icon`) is applied; anything you don't pass is left
untouched, so re-running this with just a new `icon` won't reset the
title back to its default. Existing links (e.g. `child` links to
collections added since) are preserved.

## Examples

``` r
tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni", title = "Sample Catalog")
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b6d21ab5e/catalog.json
```
