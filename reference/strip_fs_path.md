# Recursively strip the `fs_path` S3 class from any values in a STAC object

Hrefs built via
[`fs::path()`](https://fs.r-lib.org/reference/path.html)/[`fs::path_rel()`](https://fs.r-lib.org/reference/path_math.html)
carry an `fs_path` class on top of the underlying character value. The
same href read back from JSON after a round-trip (via
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md))
has no such class - so a plain
[`identical()`](https://rdrr.io/r/base/identical.html) between a
freshly-rebuilt object (fs_path hrefs) and one just read from disk
(plain character hrefs) reports "changed" even when every string value
actually matches. Every change-detection comparison in this package runs
both sides through this first, the same way
[`extents_equal()`](https://wiesehahn.github.io/managelidar/reference/extents_equal.md)
normalizes away the matrix-vs-list representation difference for
extents.

## Usage

``` r
strip_fs_path(x)
```

## Arguments

- x:

  Any R object (typically a STAC list structure)

## Value

The same structure with `fs_path` classing removed
