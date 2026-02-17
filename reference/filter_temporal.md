# Filter point cloud files by temporal extent

Filter point cloud files by temporal extent

## Usage

``` r
filter_temporal(path, start, end = NULL, verbose = TRUE)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- start:

  POSIXct, Date, or character. Start of temporal range (inclusive).
  Character strings are parsed as ISO 8601 datetime (e.g., "2024-03-27"
  or "2024-03-27T10:30:00Z"). Can also be year ("2024"), year-month
  ("2024-03"), or full date ("2024-03-27").

- end:

  POSIXct, Date, or character. End of temporal range (inclusive). If
  NULL (default), the end is automatically determined based on the
  granularity of `start`:

  - Year only ("2024"): end of that year

  - Year-month ("2024-03"): end of that month

  - Full date ("2024-03-27"): end of that day (23:59:59)

  - Full datetime: same as start (exact match)

- verbose:

  Logical. If TRUE (default), prints information about filtering
  results.

## Value

A VPC object (list) containing only features within the temporal range.
Returns NULL invisibly if no features match the filter.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*.laz")

# Filter by single day (all features from that day)
vpc <- las_files |> filter_temporal("2024-03-27")
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by month (all features from March 2024)
vpc <- las_files |> filter_temporal("2024-03")
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by year (all features from 2024)
vpc <- las_files |> filter_temporal("2024")
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by explicit date range
vpc <- las_files |> filter_temporal("2024-03-01", "2024-03-31")
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by datetime range
vpc <- las_files |> filter_temporal("2024-03-27T00:00:00Z", "2024-03-27T12:00:00Z")
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Using Date objects
vpc <- las_files |> filter_temporal(as.Date("2024-03-27"))
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
