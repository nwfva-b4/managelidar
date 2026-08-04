# Validate LASfile names according to a naming standard

`check_names()` verifies whether LAS/LAZ/COPC file names conform to
either the German AdV standard or the NWFVA standard for tiled LiDAR
data.

## Usage

``` r
check_names(
  path,
  standard = c("adv", "nwfva"),
  region = NULL,
  from_csv = NULL,
  epsg = 25832L,
  full.names = FALSE,
  product = NULL,
  copc = FALSE,
  campaign = NULL,
  platform = "als"
)
```

## Arguments

- path:

  Character vector. Paths to LAS/LAZ/COPC files, directories containing
  such files, or a VPC object already loaded in R.

- standard:

  Character. Naming standard to check against: `"adv"` (default) or
  `"nwfva"`.

- region:

  Optional character vector of two-letter region codes. If `NULL`, the
  region is automatically inferred from file bounding boxes.

- from_csv:

  Optional path to CSV file for year determination. If provided, used to
  match acquisition dates for tiles without GPStime.

- epsg:

  Integer. EPSG code used as fallback CRS when a file does not contain a
  valid CRS. Default is 25832 (ETRS89 / UTM zone 32N).

- full.names:

  Logical. If `TRUE`, returns full file paths in `name_is` and
  `name_should`; otherwise, only the base file names.

- product:

  Character. Data-product token embedded in the filename (the AdV
  standard calls this a "prefix"). Defaults to `"3dm"` for
  `standard = "adv"` and `"punktwolke"` for `standard = "nwfva"`.

- copc:

  Logical. Whether the files are expected to be COPC (`.copc.laz`). Only
  relevant for `standard = "adv"`.

- campaign:

  Character. Required when `standard = "nwfva"`: a single
  `surveyarea_contractor` label (e.g. `"solling_sgb4"`); cannot be
  derived from the data.

- platform:

  Character. Platform token, only used for `standard = "nwfva"` (default
  `"als"`).

## Value

A `data.frame` with one row per file and columns:

- name_is:

  Existing file name or path

- name_should:

  Expected file name according to the chosen standard

- correct:

  Logical indicating whether the existing name matches the standard

- date_source:

  How the date (year) was extracted

## Details

AdV file names follow the schema:
`product_utmzone_minx_miny_tilesize_region_year.laz`. Example:
`3dm_32_547_5724_1_ni_2024.laz`. See the [ADV
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111)
for details.

NWFVA file names follow the schema:
`region_platform_year_campaign_product_x_y.laz`. Example:
`ni_als_2024_solling_sgb4_punktwolke_550000_5730000.laz`, where `x`/`y`
are the lower-left corner of the containing standard 1000x1000m tile
(full meters, grid-snapped) and `campaign` is a manually supplied
`surveyarea_contractor` label.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")

las_files |> check_names()
#>                             name_is                   name_should correct
#> 1 3dm_32_547_5724_1_ni_20240327.laz 3dm_32_547_5724_1_ni_2024.laz   FALSE
#> 2 3dm_32_547_5725_1_ni_20240327.laz 3dm_32_547_5725_1_ni_2024.laz   FALSE
#> 3 3dm_32_548_5724_1_ni_20240327.laz 3dm_32_548_5724_1_ni_2024.laz   FALSE
#> 4 3dm_32_548_5725_1_ni_20240327.laz 3dm_32_548_5725_1_ni_2024.laz   FALSE
#>           date_source
#> 1 gpstime_first_point
#> 2 gpstime_first_point
#> 3 gpstime_first_point
#> 4 gpstime_first_point

las_files |> check_names(standard = "nwfva", region = "ni", campaign = "solling_sgb4")
#>                             name_is
#> 1 3dm_32_547_5724_1_ni_20240327.laz
#> 2 3dm_32_547_5725_1_ni_20240327.laz
#> 3 3dm_32_548_5724_1_ni_20240327.laz
#> 4 3dm_32_548_5725_1_ni_20240327.laz
#>                                              name_should correct
#> 1 ni_als_2024_solling_sgb4_punktwolke_547000_5724000.laz   FALSE
#> 2 ni_als_2024_solling_sgb4_punktwolke_547000_5725000.laz   FALSE
#> 3 ni_als_2024_solling_sgb4_punktwolke_548000_5724000.laz   FALSE
#> 4 ni_als_2024_solling_sgb4_punktwolke_548000_5725000.laz   FALSE
#>           date_source
#> 1 gpstime_first_point
#> 2 gpstime_first_point
#> 3 gpstime_first_point
#> 4 gpstime_first_point
```
