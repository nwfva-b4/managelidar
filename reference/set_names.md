# Set LASfile names according to ADV standard

`set_names()` renames LAS/LAZ/COPC files to match the [ADV naming
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111).

## Usage

``` r
set_names(
  path,
  prefix = "3dm",
  region = NULL,
  from_csv = NULL,
  copc = FALSE,
  epsg = 25832L,
  dry_run = FALSE,
  verbose = FALSE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file or a directory containing
  LASfiles.

- prefix:

  Character. Naming prefix (default `"3dm"`).

- region:

  Character. Federal state abbreviation (optional). Automatically
  determined if `NULL`.

- from_csv:

  Character. Path to CSV file containing acquisition dates used for year
  correction in filenames where data does not contain valid GPS time.

- copc:

  Logical. Whether files are COPC (`.copc.laz`, default `FALSE`).

- epsg:

  Integer. EPSG code for the coordinate reference system (default
  `25832L`).

- dry_run:

  Logical. If `TRUE`, only preview renaming without modifying files
  (default `FALSE`).

- verbose:

  Logical. Print messages and a preview of renaming (default `FALSE`).

## Value

Invisibly returns a `data.frame` with columns `from` and `to` showing
original and new filenames.

## Details

Files are expected to follow the schema:
`prefix_utmzone_minx_miny_tilesize_region_year.laz`

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
set_names(f, verbose = TRUE, dry_run = TRUE)
#> Files to be renamed (from → to):
#>                               from                            to
#>  3dm_32_547_5724_1_ni_20240327.laz 3dm_32_547_5724_1_ni_2024.laz
#>  3dm_32_547_5725_1_ni_20240327.laz 3dm_32_547_5725_1_ni_2024.laz
#>  3dm_32_548_5724_1_ni_20240327.laz 3dm_32_548_5724_1_ni_2024.laz
#>  3dm_32_548_5725_1_ni_20230904.laz 3dm_32_548_5725_1_ni_2023.laz
#>  3dm_32_548_5725_1_ni_20240327.laz 3dm_32_548_5725_1_ni_2024.laz
#> Dry run enabled: no files were renamed.
```
