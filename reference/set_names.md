# Set LASfile names according to a naming standard

`set_names()` renames LAS/LAZ/COPC files to match either the [ADV naming
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111)
or the NWFVA naming standard. See
[`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)
for the exact filename schemas.

## Usage

``` r
set_names(
  path,
  standard = c("adv", "nwfva"),
  region = NULL,
  from_csv = NULL,
  epsg = 25832L,
  product = NULL,
  copc = FALSE,
  campaign = NULL,
  platform = "als",
  dry_run = FALSE,
  verbose = FALSE
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

- dry_run:

  Logical. If `TRUE`, only preview renaming without modifying files
  (default `FALSE`).

- verbose:

  Logical. Print messages and a preview of renaming (default `FALSE`).

## Value

Invisibly returns a `data.frame` with columns `from` and `to` showing
original and new filenames.

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

set_names(f,
  standard = "nwfva", region = "ni", campaign = "solling_sgb4",
  dry_run = TRUE, verbose = TRUE
)
#> Files to be renamed (from → to):
#>                               from
#>  3dm_32_547_5724_1_ni_20240327.laz
#>  3dm_32_547_5725_1_ni_20240327.laz
#>  3dm_32_548_5724_1_ni_20240327.laz
#>  3dm_32_548_5725_1_ni_20230904.laz
#>  3dm_32_548_5725_1_ni_20240327.laz
#>                                                      to
#>  ni_als_2024_solling_sgb4_punktwolke_547000_5724000.laz
#>  ni_als_2024_solling_sgb4_punktwolke_547000_5725000.laz
#>  ni_als_2024_solling_sgb4_punktwolke_548000_5724000.laz
#>  ni_als_2023_solling_sgb4_punktwolke_548000_5725000.laz
#>  ni_als_2024_solling_sgb4_punktwolke_548000_5725000.laz
#> Dry run enabled: no files were renamed.
```
