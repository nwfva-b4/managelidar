# Assemble a filename following the German AdV standard

Pure filename assembly (no I/O):
`product_zone_minx_miny_tilesize_region_year.ext`.

## Usage

``` r
adv_filename(
  product,
  zone,
  minx,
  miny,
  tilesize,
  region,
  year,
  ext,
  copc = FALSE
)
```

## Arguments

- product:

  Character. Data-product token (AdV calls this a "prefix", e.g.
  `"3dm"`).

- zone, minx, miny, tilesize, region, year:

  Components as returned by
  [`resolve_naming_components()`](https://wiesehahn.github.io/managelidar/reference/resolve_naming_components.md).

- ext:

  Character. File extension (without leading dot).

- copc:

  Logical. Whether to insert a `.copc` suffix before the extension.

## Value

Character vector of assembled filenames.
