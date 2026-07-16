# Add LASfile items to an existing STAC collection

Converts LASfiles (via VPC) to STAC items and writes them into an
existing collection, updating the collection's extent and summaries.

## Usage

``` r
stac_add_items(collection, path, overwrite_items = FALSE, footprints = TRUE)
```

## Arguments

- collection:

  Path to an existing `collection.json`, typically the output of
  [`stac_add_collection()`](https://wiesehahn.github.io/managelidar/reference/stac_add_collection.md).

- path:

  Character vector of input paths, or a list containing VPC objects. Can
  be a mix of file paths (strings) and VPC objects (lists with
  `type = "FeatureCollection"`).

- overwrite_items:

  Logical. If `TRUE`, overwrite existing item files. Default is `FALSE`
  (skip existing items).

- footprints:

  Logical. If `TRUE` (default), also maintain a footprints GeoPackage
  asset built from the combined VPC via
  [`write_gpkg()`](https://wiesehahn.github.io/managelidar/reference/write_gpkg.md) -
  one feature per item with queryable metadata attributes, registered as
  `collection_obj$assets$footprints`. The combined VPC asset itself
  (`collection_obj$assets$vpc`) is always maintained regardless of this
  argument.

## Value

Path to `collection.json` (invisibly), for piping into further
`stac_add_items()` calls.

## Details

If the collection is currently empty, its placeholder extent is
*replaced* with the extent computed from this batch of items. If the
collection already contains items, the new extent is *merged* with the
existing one instead.

## Examples

``` r
cat <- tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni") 
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b4bf85e01/catalog.json
col |>
  stac_add_collection(id = "lidar_ni_2023", title = "Lidar Solling 2023") |>
  stac_add_collection(id = "2023_q3", title = "Q3 2023 Data")
#> Error in enc2utf8(path): argument is not a character vector

folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*.laz")
items <- col |>
  stac_add_items(path = las_files)
#> Error in enc2utf8(path): argument is not a character vector
```
