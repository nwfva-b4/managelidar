# Processing raw ALS data with raw_to_processed

[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
converts raw ALS point cloud files into quality-controlled, standardised
outputs following either the German AdV or the NWFVA naming convention.
It handles a full processing pipeline — CRS validation,
reclassification, noise filtering, intensity normalisation, spatial
indexing, and metadata generation — with optional parallelisation for
large datasets.

## Basic usage

``` r

library(managelidar)

# AdV naming convention (default)
raw_to_processed(
  path    = "path/to/raw/",
  out_dir = "path/to/output/"
)

# NWFVA naming convention - a dedicated wrapper, process_nwfva(), also
# exists for this, hiding the standard/platform/product parameters below
raw_to_processed(
  path     = "path/to/raw/",
  out_dir  = "J:/lidar",
  standard = "nwfva",
  campaign = "solling_sgb4"
)
```

`path` accepts a single file, a directory, a character vector of file
paths, or a VPC file. All LAS, LAZ, and COPC formats are supported.

## Parameters

| Parameter | Default | Description |
|----|----|----|
| `path` | — | Input file(s), directory, or VPC |
| `out_dir` | [`tempdir()`](https://rdrr.io/r/base/tempfile.html) | Root directory for point cloud/overview/metadata outputs |
| `log_dir` | [`tempdir()`](https://rdrr.io/r/base/tempfile.html) | Root directory for logfiles and data summaries (independent of `out_dir`) |
| `epsg` | `25832L` | Fallback EPSG when CRS is missing or invalid |
| `standard` | `"adv"` | Output naming/path convention: `"adv"` or `"nwfva"` |
| `region` | `NULL` | Two-letter state code (e.g. `"ni"`); auto-detected if `NULL` |
| `from_csv` | `NULL` | CSV with acquisition dates for files without valid GPS time |
| `campaign` | `NULL` | Required for `standard = "nwfva"`: a `surveyarea_contractor` label (e.g. `"solling_sgb4"`) |
| `platform` | `"als"` | Platform token, only used for `standard = "nwfva"` |
| `product` | `NULL` | Data-product/prefix token; defaults to `"3dm"` (AdV) or `"punktwolke"` (NWFVA) |
| `workers` | `NULL` | Number of parallel workers; see [Parallelisation](#parallelisation) |
| `reclassify` | `TRUE` | Remap AdV/LGLN classification schemes to ASPRS |
| `classify_noise` | `TRUE` | Classify noise points |
| `classify_ground` | `TRUE` | Classify ground points |
| `normalize_intensity` | `TRUE` | Normalize intensity range |
| `verbose` | `TRUE` | Print progress messages |

## Density-dependent stages

`reclassify`, `classify_noise`, `classify_ground`, and
`normalize_intensity` can each be turned off individually.
`classify_noise` and `classify_ground` in particular are
density-dependent: on sparse or very small point clouds they can
classify most or all points as noise, which then breaks overview
generation (it excludes noise points from the rasterized CHM). This is
mainly useful when testing against such data:

``` r

raw_to_processed(
  path = "path/to/sparse/test/data/",
  out_dir = "path/to/output/",
  classify_noise = FALSE,
  classify_ground = FALSE
)
```

## Output structure

Logfiles and data summaries are always written under the independent
`log_dir/` (defaults to
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), can point to a
different location than `out_dir`):

    log_dir/
    └── logfiles/
        ├── processing_log_YYYY-MM-DD_HH-MM-SS.json
        └── summaries_YYYY-MM-DD_HH-MM-SS/
            ├── files_in/
            │   └── {original_input_name}.json
            └── files_out/
                └── {generated_filename}.json

| Directory | Contents |
|----|----|
| `logfiles/` | JSON processing log per run, plus a timestamped `summaries_.../` subfolder of per-file summaries |

Each run gets its own timestamped `summaries_YYYY-MM-DD_HH-MM-SS/`
subfolder. `files_in/` uses the **original input filename** before
renaming. `files_out/` uses the **generated, standard-compliant
filename**.

### AdV output structure (`standard = "adv"`, default)

Point cloud outputs are written under a flat structure in `out_dir/`:

    out_dir/
    ├── pointcloud/
    │   └── 3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.laz
    ├── metadata/
    │   └── 3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.vpc
    └── overviews/
        └── 3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.webp

| Directory | Contents |
|----|----|
| `pointcloud/` | Processed LAZ files with embedded spatial index (`.lax`) |
| `metadata/` | Per-file VPC files with extended STAC-compatible metadata |
| `overviews/` | WEBP images of maximum elevation, coloured with the viridis palette |

### NWFVA output structure (`standard = "nwfva"`)

Outputs instead nest under `out_dir` by
region/platform/year/campaign/product, since NWFVA encodes the on-disk
location as part of the convention:

    out_dir/
    └── {region}/{platform}/{year}/{campaign}/{product}/
        ├── daten/
        │   └── {region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.laz
        └── doku/
            ├── vpc/
            │   └── {region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.vpc
            └── overview/
                └── {region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.webp

For example, with `out_dir = "J:/lidar"`, `region = "ni"`,
`campaign = "solling_sgb4"`:
`J:/lidar/ni/als/2024/solling_sgb4/punktwolke/daten/ni_als_2024_solling_sgb4_punktwolke_550000_5730000.laz`.

Since year (and therefore the whole path) can differ per file in a
multi-temporal batch, these directories are created per file rather than
once up front.

## Filename convention

Output files follow either the AdV standard:

    3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.laz

For example: `3dm_32_547_5724_1_ni_2023.laz`

or the NWFVA standard:

    {region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.laz

For example: `ni_als_2024_solling_sgb4_punktwolke_550000_5730000.laz`,
where `x`/`y` are the lower-left corner of the containing standard
1000x1000m tile (full meters, grid-snapped) - e.g. `550000` even if the
actual data extent’s min corner is `550011`.

The year is derived from the GPStime of the first point in the point
cloud if possible, and from median GPStime or header information
otherwise. The `region` code is either supplied via the `region`
parameter or auto-detected by intersecting tile centroids with federal
state boundaries. `campaign` (NWFVA only) is always manually supplied,
since it cannot be derived from the data.

If GPS time is unavailable or invalid, a `from_csv` table of acquisition
dates can also be used as a fallback. The source of the date is recorded
in the VPC metadata under `date_source` (`"gpstime_median"`,
`"gpstime_first_point"`, `"header_creation_year"` or `"csv"`).

## CRS handling

The function validates the CRS of each file before processing. A CRS is
considered invalid if it is missing (`0`), unrecognised (e.g. `32767`),
or not resolvable by
[`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html).
When an invalid CRS is detected,
[`lasR::set_crs()`](https://rdrr.io/pkg/lasR/man/set_crs.html) is
prepended to the pipeline using the `epsg` fallback.

``` r

# Files from a campaign stored without CRS — set explicitly (default)
raw_to_processed(
  path = "path/to/raw/",
  out_dir = "path/to/output/",
  epsg = 25832L
)
```

## Classification reclassification

Raw ALS data from German federal states often uses non-standard
classification schemes (AdV or legacy LGLN).
[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
automatically detects the scheme from class proportions and converts to
ASPRS standard before further processing:

- **Legacy LGLN** — detected when class 13 represents \> 1 % of points
- **AdV** — detected when class 20 represents \> 10 % of points
- **ASPRS / unclassified** — no reclassification applied; only undefined
  classes above 22 are collapsed to unclassified (1)

## Parallelisation

Processing runs sequentially for fewer than 20 files and in parallel for
20 or more, using half of available logical CPU cores by default. The
number of workers is always capped at half the available cores to leave
headroom for memory and system processes.

``` r

# Force sequential processing regardless of file count
raw_to_processed(path = "path/to/raw/", out_dir = "path/to/output/", workers = 1L)

# Use a specific number of workers (capped at half available cores)
raw_to_processed(path = "path/to/raw/", out_dir = "path/to/output/", workers = 4L)

# Default: auto (parallel for >= 20 files, sequential otherwise)
raw_to_processed(path = "path/to/raw/", out_dir = "path/to/output/")
```

Parallel workers are spawned via `mirai` and load the `managelidar`
package automatically. Each worker processes one file independently;
errors in individual files are caught and recorded in the log without
affecting other files.

## Resuming interrupted runs

[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
reads existing log files in `log_dir/logfiles/` at startup and skips any
input files that were already processed successfully. This means
interrupted runs can be resumed simply by calling the function again
with the same arguments — only failed or unprocessed files will be
re-attempted.

``` r

# First run — processes all 50 files; 3 fail
raw_to_processed(path = files, out_dir = "path/to/output/")

# Second run — skips 47 successful files, retries the 3 failed ones
raw_to_processed(path = files, out_dir = "path/to/output/")
```

## Output validation and rollback

If any expected output is missing or empty after processing, **all
outputs for that file are deleted** before the error is recorded. This
prevents partial results from accumulating across runs and ensures that
a file listed as failed in the log truly has no outputs on disk.

Expected outputs checked per file (in the pointcloud/vpc/overview
directories for whichever `standard` was used - see **Output
structure**):

- `.laz` pointcloud file
- `.vpc` metadata file
- `.webp` overview image
- `.json` in `logfiles/summaries_.../files_in/`
- `.json` in `logfiles/summaries_.../files_out/`

## The processing log

Each run writes a timestamped JSON log to `logfiles/`. The log records
the function call, package and dependency versions, all parameters, and
a per-file entry with status, duration, and any error messages.

``` json
{
  "processing": { "timestamp_start": "...", "duration_seconds": 123.4 },
  "parameters": { "out_dir": "...", "epsg": 25832 },
  "files": [
    {
      "input": "path/to/raw/tile.laz",
      "output": "path/to/output/pointcloud/3dm_32_547_5724_1_ni_2023.laz",
      "status": "success",
      "duration_seconds": 45.2
    }
  ],
  "summary": {
    "files_total": 20,
    "files_processed": 19,
    "files_failed": 1
  }
}
```

Possible status values:

| Status | Meaning |
|----|----|
| `success` | All outputs written and validated |
| `success_with_warnings` | Processed successfully, non-fatal warnings raised |
| `skipped_existing` | Output already present from a previous run |
| `skipped_locked` | Another parallel worker is currently writing this output |
| `failed` | Processing failed; all partial outputs removed |

## Return value

[`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
returns a list of output file paths (one per input file) invisibly.
Failed files return `NULL` in the corresponding position.

``` r

results <- raw_to_processed(
  path    = "path/to/raw/",
  out_dir = "path/to/output/"
)

# filter to successful outputs
successful <- Filter(Negate(is.null), results)
```
