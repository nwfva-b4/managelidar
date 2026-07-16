# Recompute and register a collection's footprints GeoPackage asset

Reuses
[`write_gpkg()`](https://wiesehahn.github.io/managelidar/reference/write_gpkg.md)
to convert the combined VPC (from
[`update_vpc_asset()`](https://wiesehahn.github.io/managelidar/reference/update_vpc_asset.md))
into a queryable GeoPackage - one feature per item, with its footprint
geometry and metadata as attributes, unlike a plain GeoJSON where
per-tile attributes aren't easily queryable in GIS software.

## Usage

``` r
update_footprints_asset(collection_obj, collection_dir, vpc, crs)
```

## Arguments

- collection_obj:

  Collection object (list); `$assets` is updated

- collection_dir:

  Path to collection directory

- vpc:

  The combined VPC object, as returned by
  [`update_vpc_asset()`](https://wiesehahn.github.io/managelidar/reference/update_vpc_asset.md)

- crs:

  EPSG code to reproject the footprints to (the collection's own CRS)

## Value

Updated `collection_obj`

## Details

Deletes any existing file at the destination first:
[`write_gpkg()`](https://wiesehahn.github.io/managelidar/reference/write_gpkg.md)
checks its own `overwrite` argument before writing, but doesn't delete
the existing file itself, and
[`sf::st_write()`](https://r-spatial.github.io/sf/reference/st_write.html)
can otherwise behave ambiguously (refuse, or append a duplicate layer)
when the destination GeoPackage already exists - which it will, since
this gets called again on the same path every time items are added.
