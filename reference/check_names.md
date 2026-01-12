# Validate LAS file names according to the ADV standard

`check_names()` verifies whether LAS/LAZ/COPC file names conform to the
German AdV standard for tiled LiDAR data. File names are expected to
follow the schema: `prefix_utmzone_minx_miny_tilesize_region_year.laz`.
Example: `3dm_32_547_5724_1_ni_2024.laz`. See the [ADV
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111)
for details.

## Usage

``` r
check_names(
  path,
  prefix = "3dm",
  zone = 32,
  region = NULL,
  year = NULL,
  copc = FALSE,
  full.names = FALSE
)
```

## Arguments

- path:

  Character vector. Paths to LAS/LAZ/COPC files or directories
  containing such files.

- prefix:

  Character scalar. Naming prefix (default: `"3dm"`).

- zone:

  Integer scalar. UTM zone (default: `32`).

- region:

  Optional character vector of two-letter region codes. If `NULL`, the
  region is automatically inferred from file bounding boxes.

- year:

  Optional acquisition year (`YYYY`) or path to CSV file. If `NULL`, the
  year is derived from the LAS header or GPStime metadata.

- copc:

  Logical. Whether the files are expected to be COPC (`.copc.laz`).

- full.names:

  Logical. If `TRUE`, returns full file paths in `name_is` and
  `name_should`; otherwise, only the base file names.

## Value

A `data.frame` with one row per file and columns:

- name_is:

  Existing file name or path

- name_should:

  Expected file name according to AdV standard

- correct:

  Logical indicating whether the existing name matches the standard

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
check_names(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
