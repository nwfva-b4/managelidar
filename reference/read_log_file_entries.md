# Parse a single processing-log JSON file into a data.frame of file entries

Parse a single processing-log JSON file into a data.frame of file
entries

## Usage

``` r
read_log_file_entries(log_file)
```

## Arguments

- log_file:

  Character. Path to one `processing_log_*.json` file.

## Value

A data.frame with columns `input`, `output`, `status`, `size_in`,
`size_out`, or `NULL` if the log contains no file entries.
