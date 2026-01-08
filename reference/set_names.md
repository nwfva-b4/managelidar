# Set LAS file names according to ADV standard

`set_names()` renames LAS/LAZ/COPC files to match the [ADV naming
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111).

## Usage

``` r
set_names(
  path,
  prefix = "3dm",
  zone = 32,
  region = NULL,
  year = NULL,
  copc = FALSE,
  dry_run = FALSE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file or a directory containing LAS
  files.

- prefix:

  Character. Naming prefix (default `"3dm"`).

- zone:

  Integer. UTM zone (default `32`).

- region:

  Character. Federal state abbreviation (optional). Automatically
  determined if `NULL`.

- year:

  Integer or character. Acquisition year to append to filenames
  (optional). If `NULL`, the year is derived from the file.

- copc:

  Logical. Whether files are COPC (`.copc.laz`, default `FALSE`).

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
set_names(copy, verbose = TRUE, dry_run = TRUE)
#> Error in set_names(copy, verbose = TRUE, dry_run = TRUE): unused argument (verbose = TRUE)
```
