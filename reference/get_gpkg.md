# Create a Geopackage containing metadata of LASfiles

`get_gpkg()` converts the metadata of a Virtual Point Cloud (.vpc) or a
collection of LAS/LAZ/COPC files into Geopackage. VPCs can be read and
visualized by QGIS, however individual tiles (features) can not be
queried as is. To do this we convert it to a Geopackage, which can
easily be explored in any GIS. Each LAS tile becomes a feature with its
spatial extent and some metadata.

## Usage

``` r
get_gpkg(
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

## Value

Invisibly returns an `sf` object representing the tiles written to the
Geopackage.

## Details

Summary metrics (optional) can be included by setting `metrics = TRUE`
for default metrics or providing a character vector of custom metrics.
Computing metrics requires reading the actual point data, und thus can
be much slower. See
[`get_summary()`](https://wiesehahn.github.io/managelidar/reference/get_summary.md)
for details.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
las_files |> get_gpkg()
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
