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

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
file <- list.files(folder, full.names = TRUE)[1]
get_intersection(folder, file)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
