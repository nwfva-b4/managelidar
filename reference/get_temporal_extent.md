# Get the temporal extent of LASfiles (individually or combined)

Extracts the temporal extent (acquisition dates) from LASfiles. Can
return dates per file or the combined date range of all files.

## Usage

``` r
get_temporal_extent(
  path,
  per_file = TRUE,
  full.names = FALSE,
  from_csv = NULL,
  return_referenceyear = FALSE,
  fix_false_gpstime = TRUE,
  epsg = 25832L,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual
  Point Cloud (.vpc) referencing these files.

- per_file:

  Logical. If `TRUE` (default), returns dates per file. If `FALSE`,
  returns combined date range of all files.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; otherwise
  base filenames (default). Only used when `per_file = TRUE`.

- from_csv:

  Character or NULL. If provided, path to a CSV file containing
  acquisition dates for tiles without GPS time. The CSV must have
  columns `minx`, `miny` (tile coordinates in km) and `date`
  (YYYY-MM-DD). If NULL (default), dates for non-GPS tiles are extracted
  from file headers.

- return_referenceyear:

  Logical. If `TRUE`, returns the reference year instead of the
  acquisition date (e.g., reference year 2015 for data acquired in
  November or December 2014). Default is `FALSE`.

- fix_false_gpstime:

  Logical. If `TRUE` (default), detects files that claim GPS time
  encoding in their header but contain week-second timestamps instead of
  standard GPS time. Such files produce spurious dates in the range
  2011-09-14 to 2011-09-21 when decoded as GPS time. Affected files are
  silently reclassified as non-GPS and their dates are resolved via CSV
  or header fallback instead.

- epsg:

  Integer. EPSG code used as fallback CRS when a file does not contain a
  valid CRS. Default is 25832 (ETRS89 / UTM zone 32N).

- verbose:

  Logical. If `TRUE` (default), prints temporal extent information.

## Value

When `per_file = TRUE`: A `data.frame` with columns:

- filename:

  Filename of the LASfile.

- date:

  Acquisition date (Date object) or reference year (numeric) if
  `return_referenceyear = TRUE`.

- date_source:

  Character. One of `gpstime_first_point` (files with valid GPStime),
  `csv` (matched from CSV file), or `header_creation_year` (from file
  header).

When `per_file = FALSE`: A single-row data.frame with `start` and `end`
(Date objects or numeric years depending on `return_referenceyear`).

## Details

For LAS 1.3+ files with GPS time encoding, the function extracts the
date from the first point. For older files without GPS time, if
`from_csv` is provided, the function assigns the closest acquisition
date prior to the processing date from the CSV file based on tile
coordinates. Otherwise, the date is extracted from the LAS header
(processing date).

When `return_referenceyear = TRUE`, November and December acquisitions
are shifted to the following year to standardize reference years.

## See also

[`get_spatial_extent`](https://wiesehahn.github.io/managelidar/reference/get_spatial_extent.md),
[`filter_temporal`](https://wiesehahn.github.io/managelidar/reference/filter_temporal.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = TRUE, pattern = "*.laz")

# Get dates per file
las_files |> get_temporal_extent()
#> Get temporal extent
#>   ▼ 5 LASfiles
#>   Temporal extent: 2023-09-05 to 2024-03-27
#>                            filename       date gpstime         date_source
#> 1 3dm_32_547_5724_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 2 3dm_32_547_5725_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 3 3dm_32_548_5724_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 4 3dm_32_548_5725_1_ni_20230904.laz 2023-09-05    TRUE gpstime_first_point
#> 5 3dm_32_548_5725_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point

# Get combined date range
las_files |> get_temporal_extent(per_file = FALSE)
#> Get temporal extent
#>   ▼ 5 LASfiles
#>   Temporal extent: 2023-09-05 to 2024-03-27
#>        start        end
#> 1 2023-09-05 2024-03-27

# Get reference years
las_files |> get_temporal_extent(return_referenceyear = TRUE)
#> Get temporal extent
#>   ▼ 5 LASfiles
#>   Temporal extent: 2023 to 2024
#>                            filename date gpstime         date_source
#> 1 3dm_32_547_5724_1_ni_20240327.laz 2024    TRUE gpstime_first_point
#> 2 3dm_32_547_5725_1_ni_20240327.laz 2024    TRUE gpstime_first_point
#> 3 3dm_32_548_5724_1_ni_20240327.laz 2024    TRUE gpstime_first_point
#> 4 3dm_32_548_5725_1_ni_20230904.laz 2023    TRUE gpstime_first_point
#> 5 3dm_32_548_5725_1_ni_20240327.laz 2024    TRUE gpstime_first_point

# Using CSV for reference dates
csv_path <- system.file("extdata", "acquisition_dates.csv", package = "managelidar")
get_temporal_extent(folder, from_csv = csv_path)
#> Get temporal extent
#>   ▼ 5 LASfiles
#>   Temporal extent: 2023-09-05 to 2024-03-27
#>                            filename       date gpstime         date_source
#> 1 3dm_32_547_5724_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 2 3dm_32_547_5725_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 3 3dm_32_548_5724_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
#> 4 3dm_32_548_5725_1_ni_20230904.laz 2023-09-05    TRUE gpstime_first_point
#> 5 3dm_32_548_5725_1_ni_20240327.laz 2024-03-27    TRUE gpstime_first_point
```
