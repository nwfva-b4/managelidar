# Process LiDAR data to standardized format using the NWFVA naming convention

Convenience wrapper around
[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
that always uses `standard = "nwfva"` with the ALS-pointcloud defaults
(`platform = "als"`, `product = "punktwolke"`), so callers processing
NWFVA data don't need to know about
[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)'s
more general `standard`/`platform`/`product` parameters. See
[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
for the full processing pipeline and
[`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)
for the exact NWFVA filename schema.

## Usage

``` r
process_nwfva(
  path,
  campaign,
  out_dir = tempdir(),
  log_dir = tempdir(),
  region = NULL,
  from_csv = NULL,
  epsg = 25832L,
  workers = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to LAS/LAZ/COPC file(s), directory, or VPC.

- campaign:

  Character. A single `surveyarea_contractor` label (e.g.
  `"solling_sgb4"`); cannot be derived from the data.

- out_dir:

  Character. Output root directory; outputs are nested under
  `{out_dir}/{region}/als/{year}/{campaign}/punktwolke/...`.

- log_dir:

  Character. Output directory where logfiles and data summaries will be
  saved.

- region:

  Character. Two-letter region code (federal states of Germany) for
  filename generation (e.g., "ni"). If `NULL` (default), region is
  automatically inferred from file bounding boxes.

- from_csv:

  Character. Path to CSV file containing acquisition dates used for year
  correction in filenames where data does not contain valid GPS time.

- epsg:

  Integer. EPSG code for the coordinate reference system. Default is
  25832 (ETRS89 / UTM zone 32N).

- workers:

  Integer or `NULL`. Number of parallel workers. See
  [`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md).

- verbose:

  Logical. Print progress messages. Default is TRUE.

## Value

Invisibly returns a list of output file paths (NULL for failed files).

## Examples

``` r
# \donttest{
folder <- system.file("extdata", package = "managelidar")
out_dir <- tempfile("processed_nwfva_")
process_nwfva(path = folder, campaign = "solling_sgb4", out_dir = out_dir, region = "ni")
#> Process 5 LASfiles
#> Warning: GDAL Error 1: /tmp/Rtmpatnzrr/processed_nwfva_22963088ca66/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_547000_5724000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmpatnzrr/processed_nwfva_22963088ca66/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_547000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmpatnzrr/processed_nwfva_22963088ca66/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_548000_5724000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmpatnzrr/processed_nwfva_22963088ca66/ni/als/2023/solling_sgb4/punktwolke/doku/overview/ni_als_2023_solling_sgb4_punktwolke_548000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmpatnzrr/processed_nwfva_22963088ca66/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_548000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> 
#> Processing log written to: /tmp/Rtmpatnzrr/logfiles/processing_log_2026-08-04_06-46-43.json
# }
```
