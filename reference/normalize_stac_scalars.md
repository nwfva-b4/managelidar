# Recursively collapse the JSON array-of-one vs scalar ambiguity

[`write_stac()`](https://wiesehahn.github.io/managelidar/reference/write_stac.md)
writes with `auto_unbox = TRUE`, so an unnamed length-1 list like
`list("data")` (e.g. an asset's `roles`) is written as the bare JSON
string `"data"`, not the array `["data"]`. Reading that file back via
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
therefore yields a plain scalar, not a length-1 list - even though
nothing about the actual content changed. Every change-detection
comparison in this package runs both sides through this (alongside
[`strip_fs_path()`](https://wiesehahn.github.io/managelidar/reference/strip_fs_path.md))
so a freshly-built object (with e.g. `roles = list("data")`) compares
equal to its round-tripped disk version (`roles = "data"`).

## Usage

``` r
normalize_stac_scalars(x)
```

## Arguments

- x:

  Any R object (typically a STAC list structure)

## Value

The same structure with unnamed length-1 lists of an atomic scalar
collapsed to that scalar
