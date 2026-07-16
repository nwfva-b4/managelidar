# Add a visual asset (thumbnail, overview, ...) to a collection

Registers an image as a collection-level asset, using `roles` to tell
STAC Browser (and other clients) how to display it - `"thumbnail"` is
shown as a preview image on the collection's own page. For an icon shown
in headers and listings, use
[`stac_set_icon()`](https://wiesehahn.github.io/managelidar/reference/stac_set_icon.md)
instead - STAC Browser treats icons as *links*, not assets, which is a
different mechanism.

## Usage

``` r
stac_add_collection_asset(
  collection,
  source,
  roles = "thumbnail",
  key = NULL,
  title = NULL,
  copy = NULL
)
```

## Arguments

- collection:

  Path to an existing `collection.json`.

- source:

  A URL, or a path to a local image file (png, jpg/jpeg, webp, gif, or
  tif/tiff).

- roles:

  Character vector of asset roles. Defaults to `"thumbnail"`. Multiple
  roles can be combined on the same image, e.g.
  `c("thumbnail", "overview")`.

- key:

  Asset key (dictionary key under `assets`). Defaults to the first role
  (e.g. `"thumbnail"`). A second call with the same key replaces it.

- title:

  Asset title. Defaults to a title-cased version of `key`.

- copy:

  Whether to copy the image into the catalog tree rather than reference
  it in place. Defaults to `FALSE` for URLs (already web-accessible) and
  `TRUE` for local files (otherwise unreachable from a browser via
  [`stac_browse()`](https://wiesehahn.github.io/managelidar/reference/stac_browse.md)).

## Value

Path to `collection.json` (invisibly), for piping into further calls.

## Examples

``` r
cat <- tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni") 
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4241bb34/catalog.json
col <- cat |>
  stac_add_collection(id = "lidar_ni", title = "Lidar Solling", keywords = c("lidar", "ALS", "Solling", "test")) |> 
  stac_add_collection_asset(
    "https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png",
    roles = "thumbnail"
  )
#> ✔ Created collection lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4241bb34/collections/lidar_ni/collection.json
#> ✔ Updated parent lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4241bb34/catalog.json
#> ✔ Added thumbnail asset (thumbnail) to /tmp/RtmpWTNJfp/stac-managelidar-215b4241bb34/collections/lidar_ni/collection.json
```
