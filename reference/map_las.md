# Map a function over LAS/LAZ/COPC files

Internal helper to apply a function to multiple LAS files, using
parallel processing (mirai) only when beneficial.

## Usage

``` r
map_las(files, FUN)
```

## Arguments

- files:

  Character vector of LAS/LAZ/COPC file paths.

- FUN:

  Function to apply to each file.

## Value

A list with one element per file.
