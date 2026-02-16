# Get intersecting LAS files

`get_intersection()` identifies LAS/LAZ/COPC files whose spatial extents
intersect or are spatially equal between two inputs.

## Usage

``` r
get_intersection(
  path1,
  path2,
  mode = "intersects",
  as_sf = FALSE,
  full.names = FALSE
)
```

## Arguments

- path1:

  Character. Path(s) to LAS/LAZ/COPC files, a directory, or a Virtual
  Point Cloud (.vpc).

- path2:

  Character. Path(s) to LAS/LAZ/COPC files, a directory, or a Virtual
  Point Cloud (.vpc).

- mode:

  Character. Spatial predicate to use: `"intersects"` (default) or
  `"equals"`.

- as_sf:

  Logical. If `TRUE`, return results as `sf` objects; otherwise drop
  geometries (default).

- full.names:

  Logical. If `TRUE`, filenames are returned as full paths; otherwise
  base filenames (default).

## Value

A named list with two elements (`path1`, `path2`), each containing a
`data.frame` or `sf` object with column `filename` for intersecting or
equal file extents.

## Details

This function simply checks for intersection between two inputs.
[`is_multitemporal`](https://wiesehahn.github.io/managelidar/reference/is_multitemporal.md)
in contrast is a newer addition and works with a single input (which can
be a vector of multiple files/folders), in most cases
[`filter_first`](https://wiesehahn.github.io/managelidar/reference/filter_first.md)
/
[`filter_latest`](https://wiesehahn.github.io/managelidar/reference/filter_latest.md)
might be the best choice.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
file <- list.files(folder, full.names = TRUE)[1]
get_intersection(folder, file)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
