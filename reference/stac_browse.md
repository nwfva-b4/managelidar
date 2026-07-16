# Browse a STAC catalog

Opens a STAC catalog (created with
[`stac_create_catalog()`](https://wiesehahn.github.io/managelidar/reference/stac_create_catalog.md))
in your browser so you can explore its collections and items visually.
Uses either [STAC Map](https://github.com/developmentseed/stac-map) or
[STAC Browser](https://github.com/radiantearth/stac-browser).

## Usage

``` r
stac_browse(catalog, tool = "stac-browser")
```

## Arguments

- catalog:

  Path to `catalog.json` (the root of the STAC tree).

- tool:

  Can be either `"stac-browser"` (default) or `"stac-map"`.

## Value

Nothing (called for its side effect of opening a browser).

## Examples

``` r
cat <- tempfile("stac-managelidar-") |>
  stac_create_catalog(id = "lidar_ni") 
#> ✔ Created catalog lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b77b5c235/catalog.json
col <- cat |>
  stac_add_collection(id = "lidar_ni", title = "Lidar Solling")
#> ✔ Created collection lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b77b5c235/collections/lidar_ni/collection.json
#> ✔ Updated parent lidar_ni at /tmp/RtmpWTNJfp/stac-managelidar-215b77b5c235/catalog.json
cat |> stac_browse()
#> ✔ Opening catalog in your browser...
```
