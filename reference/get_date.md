# Get acquisition date from LAS files

`get_date()` derives the acquisition date for LAS/LAZ/COPC files.

## Usage

``` r
get_date(
  path,
  full.names = FALSE,
  from_csv = NULL,
  return_referenceyear = FALSE
)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing LAS
  files, or a Virtual Point Cloud (.vpc) referencing these files.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; if `FALSE`
  (default), only base filenames are returned.

- from_csv:

  Character or NULL. If provided, should be the path to a CSV file
  containing acquisition dates for tiles without GPS time. The CSV must
  have columns `minx`, `miny` (tile lower-left coordinates in km) and
  `date` (YYYY-MM-DD). If NULL (default), dates for non-GPS tiles will
  be set to `NA`.

- return_referenceyear:

  Logical. If `TRUE`, returns the reference year instead of the
  acquisition date (e.g., reference year 2015 for data acquired in
  December 2014). Default is `FALSE`.

## Value

A `data.frame` with columns:

- filename:

  Filename of the LAS file.

- date:

  Acquisition date (POSIXct for GPS-encoded files, Date for others) or
  reference year if `return_referenceyear = TRUE`.

- from:

  Character. One of `data` (for files with valid GPStime data), `csv`
  (for other files if corresponding date is in CSV file) or `header`
  (for other files)

## Details

This function attempts to determine the acquisition date for LASfiles
from embedded GPStime in the point cloud where possible (LAS 1.3+). If
this is not possible the date is extracted from processing date encoded
in the LASheader. If a valid CSV-file is provided the latest acquisition
date prior to the processing date will be returned for files without
GPStime instead of the processing date.

- For LAS 1.3+ files with GPS time encoding, the function extracts the
  date of the first point.

- For older files without GPS time, if `from_csv` is provided, the
  function will attempt to assign the closest acquisition date prior to
  the processing date from the CSV file, based on tile coordinates.

- If neither GPStime nor CSV data is available, the date is from the
  LASheader (processing date).

- `return_referenceyear = TRUE` shifts December acquisitions to the
  following year to standardize reference years.

## Examples

``` r
# Example using the package's extdata folder
f <- system.file("extdata", package = "managelidar")
get_date(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Using an external CSV for reference dates
csv_path <- system.file("extdata", "acquisition_dates_lgln.csv", package = "managelidar")
get_date(f, from_csv = csv_path)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
