# Filter point cloud files by temporal extent

Filter point cloud files by temporal extent

## Usage

``` r
filter_temporal(path, start, end = NULL, out_file = NULL)
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

- out_file:

  Optional. Path where the filtered VPC should be saved. If NULL
  (default), returns the VPC as an R object. If provided, saves to file
  and returns the file path. Must have `.vpc` extension and must not
  already exist. File is only created if filtering returns results.

## Value

If `out_file` is NULL, returns a VPC object (list) containing only
features within the temporal range. If `out_file` is provided and
results exist, returns the path to the saved `.vpc` file. Returns NULL
invisibly if no features match the filter.

## Examples

``` r
if (FALSE) { # \dontrun{
# Filter by single day (all features from that day)
las_files |> filter_temporal("2024-03-27")

# Filter by month (all features from March 2024)
las_files |> filter_temporal("2024-03")

# Filter by year (all features from 2024)
las_files |> filter_temporal("2024")

# Filter by explicit date range
las_files |> filter_temporal("2024-03-01", "2024-03-31")

# Filter by datetime range
las_files |> filter_temporal("2024-03-27T00:00:00Z", "2024-03-27T12:00:00Z")

# Using Date objects
las_files |> filter_temporal(as.Date("2024-03-27"))

# Save to file
las_files |> filter_temporal("2024-03", out_file = "march.vpc")
} # }
```
