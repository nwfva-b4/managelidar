# Find the first link with a given `rel` value

Find the first link with a given `rel` value

## Usage

``` r
find_link(links, rel)
```

## Arguments

- links:

  List of link objects (as returned by
  [`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md))

- rel:

  Relation type to search for (e.g. `"root"`, `"parent"`)

## Value

The matching link object, or `NULL` if none found
