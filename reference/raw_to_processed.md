# Process LiDAR data to standardized format

Converts incoming ALS data to quality-controlled, standardized point
clouds with comprehensive metadata and overview images.

## Usage

``` r
raw_to_processed(
  path,
  out_dir = tempdir(),
  epsg = 25832L,
  region = NULL,
  from_csv = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to LAS/LAZ/COPC file(s), directory, or VPC.

- out_dir:

  Character. Output directory where processed files and metadata will be
  saved.

- epsg:

  Integer. EPSG code for the coordinate reference system. Default is
  25832 (ETRS89 / UTM zone 32N).

- region:

  Character. Two-letter region code (federal states of Germany) for
  filename generation (e.g., "ni"). If NULL (default) region is
  automatically inferred from file bounding boxes.

- from_csv:

  Character. Path to CSV file containing acquisition dates used for year
  correction in filenames where data does not contain valid GPS time.

- verbose:

  Logical. Print progress messages. Default is TRUE.

## Value

Invisibly returns a list of output file paths (NULL for failed files).

## Details

This function performs a comprehensive quality assurance pipeline:

**Processing steps:**

- Generate AdV-compliant filenames

- Set CRS (if not present)

- Reclassify (AdV/LGLN to ASPRS scheme)

- Fix synthetic data (ReturnNumber, NumberOfReturns, GPStime)

- Filter erroneous data (ReturnNumber, NumberOfReturns, GPStime)

- Drop unused attributes

- Classify noise points

- Classify ground points

- Normalize intensity range

- Sort (optimize) point cloud

- Append spatial index

- Create overview image

- Create VPC file with additional metadata

- Create point cloud summaries

- Create log file

**Output structure:** The function creates the following directory
structure in `out_dir` if not otherwise defined:

- `pointcloud/`:

  Processed LAZ files with embedded spatial index

- `metadata/`:

  Individual VPC files with additional metadata

- `overviews/`:

  WEBP overview images (max elevation)

- `logfiles/`:

  Processing logs with timing and status information

- `logfiles/summary_in`:

  Data summaries of input LASfiles

- `logfiles/summary_out`:

  Data summaries of output LASfiles

**Filename generation:** Output files follow the German AdV naming
convention: `3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.laz`

The year is extracted from median GPS time to avoid errors from
individual erroneous points. Region can be specified or auto-detected
from input filenames.

**Performance:** Processing runs in parallel (via mirai) when 20+ files
are detected, using half of available CPU cores. A comprehensive JSON
log documents all processing steps, timing, and any warnings or errors.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage with default settings
raw_to_processed(
  path = "raw_data/",
  out_dir = "processed/"
)
} # }
```
