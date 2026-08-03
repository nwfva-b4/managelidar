# Internal helper to normalize temporal range

If `end` is not provided, it is derived from the granularity of `start`
(e.g. a bare year expands to the end of that year) via
[`parse_datetime_input()`](https://wiesehahn.github.io/managelidar/reference/parse_datetime_input.md).

## Usage

``` r
normalize_temporal_range(start, end = NULL)
```

## Arguments

- start:

  Start datetime (various formats)

- end:

  End datetime (various formats) or NULL

## Value

List with start and end POSIXct objects
