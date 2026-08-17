# Process LiDAR data to standardized format

Converts incoming ALS data to quality-controlled, standardized point
clouds with comprehensive metadata and overview images.

## Usage

``` r
raw_to_processed(
  path,
  out_dir = tempdir(),
  log_dir = tempdir(),
  epsg = 25832L,
  standard = c("adv", "nwfva"),
  region = NULL,
  from_csv = NULL,
  campaign = NULL,
  platform = "als",
  product = NULL,
  workers = NULL,
  reclassify = TRUE,
  classify_noise = TRUE,
  classify_ground = TRUE,
  normalize_intensity = TRUE,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to LAS/LAZ/COPC file(s), directory, or VPC.

- out_dir:

  Character. Output directory where processed files and metadata will be
  saved.

- log_dir:

  Character. Output directory where logfiles and data summaries will be
  saved.

- epsg:

  Integer. EPSG code for the coordinate reference system. Default is
  25832 (ETRS89 / UTM zone 32N).

- standard:

  Character. Output naming/path convention: `"adv"` (default) or
  `"nwfva"`. See
  [`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)
  for the exact filename schemas. For `"nwfva"`, output files are
  additionally organised into a nested
  `region/platform/year/campaign/product/` directory tree rather than
  `out_dir`'s flat `pointcloud/`/`overviews/`/`metadata/` folders - see
  **Output structure**.
  [`process_nwfva()`](https://wiesehahn.github.io/managelidar/reference/process_nwfva.md)
  wraps this standard with a simpler, NWFVA-only call signature.

- region:

  Character. Two-letter region code (federal states of Germany) for
  filename generation (e.g., "ni"). If NULL (default) region is
  automatically inferred from file bounding boxes.

- from_csv:

  Character. Path to CSV file containing acquisition dates used for year
  correction in filenames where data does not contain valid GPS time.

- campaign:

  Character. Required when `standard = "nwfva"`: a single
  `surveyarea_contractor` label (e.g. `"solling_sgb4"`); cannot be
  derived from the data.

- platform:

  Character. Platform token, only used for `standard = "nwfva"` (default
  `"als"`).

- product:

  Character. Data-product token embedded in the filename (the AdV
  standard calls this a "prefix"). Defaults to `"3dm"` for
  `standard = "adv"` and `"punktwolke"` for `standard = "nwfva"`.

- workers:

  Integer or `NULL`. Number of parallel workers. If `NULL` (default),
  workers are set to half of available logical cores when 20 or more
  files are detected, and sequential processing is used otherwise. Set
  to `1` to force sequential processing regardless of file count. Set to
  a positive integer to force that number of workers, up to the number
  of logical cores (100%). Requesting more than half of available cores
  triggers a warning, since each worker loads its own copy of the point
  cloud data and may exhaust available RAM.

- reclassify:

  Logical. Remap AdV/LGLN classification schemes to ASPRS (default
  `TRUE`). If `FALSE`, output classes may stay non-ASPRS, and ground
  classification (below) becomes slightly less precise. See **Processing
  steps**.

- classify_noise:

  Logical. Classify noise points (default `TRUE`). See **Processing
  steps**.

- classify_ground:

  Logical. Classify ground points (default `TRUE`). Density-dependent
  like `classify_noise`. See **Processing steps**.

- normalize_intensity:

  Logical. Normalize intensity range (default `TRUE`). See **Processing
  steps**.

- verbose:

  Logical. Print progress messages. Default is TRUE.

## Value

Invisibly returns a list of output file paths (NULL for failed files).

## Details

This function performs a comprehensive quality assurance pipeline:

**Processing steps:**

- Generate standard-compliant filenames

- Set CRS (if not present)

- Reclassify (AdV/LGLN to ASPRS scheme) - `reclassify`

- Fix synthetic data (ReturnNumber, NumberOfReturns, GPStime)

- Filter erroneous data (ReturnNumber, NumberOfReturns, GPStime)

- Drop unused attributes

- Correct overlap points

- Classify noise points - `classify_noise`

- Classify ground points - `classify_ground`

- Normalize intensity range - `normalize_intensity`

- Sort (optimize) point cloud

- Append spatial index

- Create overview image

- Create VPC file with additional metadata

- Create point cloud summaries

- Create log file

The four steps marked above are density-dependent and can be turned off
individually (all default `TRUE`, i.e. current behavior).

**Output structure:** For `standard = "adv"` (default), the function
creates the following flat directory structure in `out_dir`:

- `pointcloud/`:

  Processed LAZ files with embedded spatial index

- `metadata/`:

  Individual VPC files with additional metadata

- `overviews/`:

  WEBP overview images (max elevation)

For `standard = "nwfva"`, outputs instead nest under `out_dir` as:

- `{region}/{platform}/{year}/{campaign}/{product}/daten/`:

  Processed LAZ files

- `{region}/{platform}/{year}/{campaign}/{product}/doku/vpc/`:

  VPC metadata

- `{region}/{platform}/{year}/{campaign}/{product}/doku/overview/`:

  WEBP overview images

For both standards, `log_dir` (independent of `out_dir`) gets the same
flat structure:

- `logfiles/`:

  Processing logs with timing and status information

- `logfiles/summaries_%Y-%m-%d_%H-%M-%S/files_in`:

  Data summaries of input LASfiles

- `logfiles/summaries_%Y-%m-%d_%H-%M-%S/files_out`:

  Data summaries of output LASfiles

**Filename generation:** Output files follow either the German AdV
naming convention
(`3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.laz`) or the NWFVA
convention
(`{region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.laz`).

The year is extracted from median GPS time to avoid errors from
individual erroneous points. Region can be specified or auto-detected
from input filenames.

**Performance:** Processing runs in parallel (via mirai) when 20+ files
are detected, using half of available CPU cores. A comprehensive JSON
log documents all processing steps, timing, and any warnings or errors.

## Examples

``` r
# \donttest{
# Basic usage with default settings (AdV naming convention)
folder <- system.file("extdata", package = "managelidar")
out_dir <- tempfile("processed_")
raw_to_processed(path = folder, out_dir = out_dir)
#> Process 5 LASfiles
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_2bdb669ef68c/overviews/3dm_32_547_5724_1_ni_2024.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_2bdb669ef68c/overviews/3dm_32_547_5725_1_ni_2024.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_2bdb669ef68c/overviews/3dm_32_548_5724_1_ni_2024.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_2bdb669ef68c/overviews/3dm_32_548_5725_1_ni_2023.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_2bdb669ef68c/overviews/3dm_32_548_5725_1_ni_2024.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> 
#> Processing log written to: /tmp/Rtmp3ntGw4/logfiles/processing_log_2026-08-17_09-51-48.json

# NWFVA naming convention
out_dir_nwfva <- tempfile("processed_nwfva_")
raw_to_processed(
  path = folder, out_dir = out_dir_nwfva,
  standard = "nwfva", region = "ni", campaign = "solling_sgb4"
)
#> Process 5 LASfiles
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_nwfva_2bdb6a5e4a8f/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_547000_5724000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_nwfva_2bdb6a5e4a8f/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_547000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_nwfva_2bdb6a5e4a8f/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_548000_5724000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_nwfva_2bdb6a5e4a8f/ni/als/2023/solling_sgb4/punktwolke/doku/overview/ni_als_2023_solling_sgb4_punktwolke_548000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> Warning: GDAL Error 1: /tmp/Rtmp3ntGw4/processed_nwfva_2bdb6a5e4a8f/ni/als/2024/solling_sgb4/punktwolke/doku/overview/ni_als_2024_solling_sgb4_punktwolke_548000_5725000.tif, band 1: Failed to compute statistics, no valid pixels found in sampling.
#> Warning: GDAL Error 6: Too many command options '0'
#> 
#> Processing log written to: /tmp/Rtmp3ntGw4/logfiles/processing_log_2026-08-17_09-51-49.json
# }
```
