# Add (or update) a collection on a STAC catalog or collection

Creates a new collection nested under a catalog or another collection. A
freshly created collection starts out empty; use
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
to populate it with items afterwards.

## Usage

``` r
stac_add_collection(
  parent,
  id = NULL,
  title,
  description = "STAC collection",
  license = "other",
  keywords = NULL,
  providers = NULL,
  summaries = NULL,
  assets = NULL,
  stac_extensions = NULL,
  thumbnail = NULL,
  overview = NULL,
  icon = NULL,
  copy = NULL
)
```

## Arguments

- parent:

  Path to the parent STAC JSON file (`catalog.json` or
  `collection.json`) when `id` is given, to create/locate a child under
  it. Or, when `id` is omitted, the path to the collection's own
  `collection.json` to update it directly - see Details.

- id:

  Collection ID. Required to create a new collection; optional when
  updating one you already have the path to (see Details).

- title:

  Collection title. Defaults to `id` for a new collection; left
  unchanged on update unless explicitly passed.

- description:

  Collection description. Defaults to `"STAC collection"` for a new
  collection; left unchanged on update unless explicitly passed.

- license:

  License string. Can be provided as [SPDX License
  identifier](https://spdx.org/licenses/) or
  [SPDX-license-expression](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/).
  Defaults to `"other"` for a new collection; left unchanged on update
  unless explicitly passed.

- keywords:

  Character vector of keywords.

- providers:

  List of provider objects, e.g.
  `list(list(name = "Org Name", roles = c("host", "producer"), url = "https://example.org"))`.
  Valid roles are `"licensor"`, `"producer"`, `"processor"`, `"host"`.

- summaries:

  List of summary objects. `proj:epsg` and `pc:type` are added
  automatically by
  [`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
  once items are added.

- assets:

  List of asset objects. For a thumbnail/overview image, prefer the
  `thumbnail`/`overview` arguments below instead of building this by
  hand.

- stac_extensions:

  Character vector of extension URLs.

- thumbnail:

  A URL, or a path to a local image file, to set as the collection's
  thumbnail asset. See
  [`stac_add_collection_asset()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection_asset.md).

- overview:

  A URL, or a path to a local image file, to set as the collection's
  overview asset. See
  [`stac_add_collection_asset()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection_asset.md).

- icon:

  A URL, or a path to a local image file, to set as the collection's
  icon link (shown in headers/listings). See
  [`stac_set_icon()`](https://wiesehahn.github.io/managelidar/reference/stac_set_icon.md).

- copy:

  Whether to copy `thumbnail`/`overview`/`icon` into the catalog tree
  rather than reference them in place. See
  [`stac_add_collection_asset()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection_asset.md)/[`stac_set_icon()`](https://wiesehahn.github.io/managelidar/reference/stac_set_icon.md)
  for the default behavior.

## Value

Path to the collection's `collection.json` (invisibly), for piping into
`stac_add_collection()` (subcollection),
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md),
or a later update call.

## Details

There are two ways to target an existing collection for update:

- Pass `parent` + `id` as usual (the combination used to create it). If
  a collection with that `id` already exists under `parent`, it's
  updated in place instead of recreated.

- Omit `id` and pass the collection's own `collection.json` path as
  `parent` instead - useful when you already have that path (e.g. from
  an earlier pipe) and don't want to look up or retype its
  `id`/location. `parent` in this mode means "the collection to update",
  not "its parent".

Either way, any argument you explicitly pass (`title`, `description`,
`license`, `keywords`, `providers`, `summaries`, `assets`,
`stac_extensions`, `thumbnail`, `overview`, `icon`) is applied; anything
you don't pass is left untouched, so re-running this to just add
`providers` won't reset the title or wipe out items already added. The
collection's `extent` is never touched here - only
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
manages it.

Directory structure created (when creating via `parent` + `id`):

- For catalog parent: `{parent_dir}/collections/{id}/`

- For collection parent: `{parent_dir}/{id}/` (subcollection)

A newly created collection is written with a placeholder empty extent
(zero bbox, `NULL` temporal interval), which
[`stac_add_items()`](https://wiesehahn.github.io/managelidar/reference/stac_add_items.md)
replaces with the real extent the first time items are added.

## Examples

``` r
col <- tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni") |>
  stac_add_collection(id = "lidar_ni_2023", title = "Lidar Solling 2023") |>
  stac_add_collection(id = "2023_q3", title = "Q3 2023 Data")
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/catalog.json
#> ✔ Created collection lidar_ni_2023 at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/collections/lidar_ni_2023/collection.json
#> ✔ Updated parent lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/catalog.json
#> ✔ Created collection 2023_q3 at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/collections/lidar_ni_2023/2023_q3/collection.json
#> ✔ Updated parent lidar_ni_2023 at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/collections/lidar_ni_2023/collection.json

# Update later using just the path - no need to know/retype its id
col |> stac_add_collection(providers = list(
  list(name = "NW-FVA", roles = c("host", "processor"), url = "https://www.nw-fva.de/")
))
#> ✔ Updated collection 2023_q3 at /tmp/RtmpWTNJfp/stac-managelidar-215b3ac58431/collections/lidar_ni_2023/2023_q3/collection.json
```
