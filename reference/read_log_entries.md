# Read all JSON processing logs in a directory into one data.frame

Read all JSON processing logs in a directory into one data.frame

## Usage

``` r
read_log_entries(log_dir)
```

## Arguments

- log_dir:

  Character. Path to the directory containing JSON log files.

## Value

A data.frame with columns `input`, `output`, `status`, `size_in`,
`size_out` combining entries from every log file, or `NULL` if no logs
exist or none contain file entries.
