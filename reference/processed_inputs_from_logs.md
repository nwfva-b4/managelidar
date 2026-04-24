# Get successfully processed input paths from existing log files

Reads all JSON processing logs in `log_dir` and returns the input file
paths that completed with a successful or skipped status. Used to avoid
reprocessing files on subsequent runs.

## Usage

``` r
processed_inputs_from_logs(log_dir)
```

## Arguments

- log_dir:

  Character. Path to the directory containing JSON log files.

## Value

Character vector of normalised input file paths that were successfully
processed. Returns `character(0)` if no logs exist or none contain
successful entries.
