# Create a Geopackage containing metadata of LASfiles

`write_gpkg()` converts the metadata of a Virtual Point Cloud (.vpc) or
a collection of LAS/LAZ/COPC files into Geopackage. VPCs can be read and
visualized by QGIS, however individual tiles (features) can not be
queried as is. To enable this we convert it to a Geopackage, which can
be easily explored in any GIS. Each LAS tile becomes a feature with its
spatial extent and some metadata.

## Usage

``` r
write_gpkg(
  path,
  out_file = tempfile(fileext = ".gpkg"),
  overwrite = FALSE,
  crs = 25832,
  metrics = NULL
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing
  LASfiles, or a Virtual Point Cloud (.vpc) file.

- out_file:

  Path to the output Geopackage (.gpkg) file (default: tempfile).

- overwrite:

  Logical. If TRUE, overwrite the output file if it exists (default:
  FALSE).

- crs:

  Integer. Optional EPSG code to reproject the VPC (default: 25832).

- metrics:

  Optional. Controls whether summary metrics are computed and added to
  the output layer.

  - `NULL` (default): no summary metrics are computed.

  - `TRUE`: compute the default set of metrics returned by
    [`get_summary()`](https://wiesehahn.github.io/managelidar/reference/get_summary.md).

  - Character vector: compute only the specified metrics, e.g.
    `c("z_mean", "classification_mode", "intensity_mean")`.

  Computing metrics requires reading the point data from all files and
  can substantially increase processing time. See
  [`get_summary()`](https://wiesehahn.github.io/managelidar/reference/get_summary.md)
  for available metrics and details.

## Value

Invisibly returns an `sf` object representing the tiles written to the
Geopackage.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
las_files |> write_gpkg()
#> Wrote Geopackage: /tmp/RtmpWTNJfp/file215b1e7362d4.gpkg
```
