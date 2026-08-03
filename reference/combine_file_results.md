# Combine a list of per-file result data.frames into one plain data.frame

Used by `get_*()` functions to combine per-file metrics into a single
table. Uses
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
rather than base [`rbind()`](https://rdrr.io/r/base/cbind.html) because
per-file error entries (e.g. from
[`map_las()`](https://wiesehahn.github.io/managelidar/reference/map_las.md)'s
failure wrapper) can have a different shape than successful entries;
`bind_rows()` fills missing columns with `NA` instead of erroring. The
tibble class is stripped so every `get_*()` function consistently
returns a plain `data.frame`.

## Usage

``` r
combine_file_results(results)
```

## Arguments

- results:

  List of data.frames (or `NULL` entries, which are dropped).

## Value

A plain `data.frame`.
