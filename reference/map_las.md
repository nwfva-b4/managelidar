# Map a function over LAS/LAZ/COPC files

Internal helper to apply a function to multiple LASfiles, optionally
using parallel processing via mirai. Errors in individual files are
caught and returned as structured failure entries rather than
propagating.

## Usage

``` r
map_las(files, FUN, workers = NULL)
```

## Arguments

- files:

  Character vector of LAS/LAZ/COPC file paths.

- FUN:

  Function to apply to each file.

- workers:

  Integer or `NULL`. Number of parallel workers. If `NULL` (default),
  workers are set to half of available logical cores when 20 or more
  files are detected, and sequential processing is used otherwise. Set
  to `1` to force sequential processing regardless of file count. Set to
  a positive integer to force that number of workers.

## Value

A list with one element per file. Failed files return a list with
`output = NULL` and a `log` entry with `status = "failed"`.
