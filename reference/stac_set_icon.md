# Set an icon on a catalog or collection

Adds a link with `rel: "icon"`. STAC Browser (and other clients) use
this - specifically a *link*, not an asset - to show a small icon in the
page header and in lists of Catalogs, Collections and Items. This works
on both catalogs and collections.

## Usage

``` r
stac_set_icon(stac_object, source, copy = NULL)
```

## Arguments

- stac_object:

  Path to a `catalog.json` or `collection.json`.

- source:

  A URL, or a path to a local image file (png, jpg/jpeg, webp, gif, or
  tif/tiff).

- copy:

  Whether to copy the image into the catalog tree rather than reference
  it in place. Defaults to `FALSE` for URLs (already web-accessible) and
  `TRUE` for local files (otherwise unreachable from a browser via
  [`stac_browse()`](https://wiesehahn.github.io/managelidar/reference/stac_browse.md)).

## Value

Path to `stac_object` (invisibly), for piping into further calls.

## Details

For a preview image shown on a collection's own page (not in listings),
use
[`stac_add_collection_asset()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection_asset.md)
with `roles = "thumbnail"` instead - that's an asset, not a link, which
is a different STAC Browser convention for a different purpose.

## Examples

``` r
cat <- tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni")
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4c742d79/catalog.json
col <- cat |>
  stac_add_collection(id = "lidar_ni", title = "Lidar Solling", keywords = c("lidar", "ALS", "Solling", "test")) |> 
  stac_set_icon("https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png")
#> ✔ Created collection lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4c742d79/collections/lidar_ni/collection.json
#> ✔ Updated parent lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4c742d79/catalog.json
#> ✔ Set icon on /tmp/RtmpWTNJfp/stac-managelidar-215b4c742d79/collections/lidar_ni/collection.json
```
