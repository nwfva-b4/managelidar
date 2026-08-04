# Resolve shared naming components from a VPC

Computes the CRS/zone, grid-snapped spatial extent, region, and year for
every feature in a VPC - the data needed by both the AdV and NWFVA
filename builders
([`adv_filename()`](https://wiesehahn.github.io/managelidar/reference/adv_filename.md),
[`nwfva_filename()`](https://wiesehahn.github.io/managelidar/reference/nwfva_filename.md)).
Standard-agnostic: the two builders differ only in how they assemble
these components into a filename string.

## Usage

``` r
resolve_naming_components(vpc, region = NULL, from_csv = NULL, epsg = 25832L)
```

## Arguments

- vpc:

  A VPC object as returned by
  [`resolve_vpc()`](https://wiesehahn.github.io/managelidar/reference/resolve_vpc.md).

- region:

  Optional character vector of two-letter region codes. If `NULL`, the
  region is automatically inferred from file bounding boxes via
  [`detect_region()`](https://wiesehahn.github.io/managelidar/reference/detect_region.md).

- from_csv:

  Optional path to CSV file for year determination.

- epsg:

  Integer. EPSG code used as fallback CRS when a file does not contain a
  valid CRS.

## Value

A list with `files`, `zone`, `minx`/`miny`/`maxx`/`maxy`, `tilesize`,
`region`, `year`, `date_source`, `ext_suffix` - one value per file
(recycled for scalar inputs like an explicit `region`).
