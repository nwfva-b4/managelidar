# Internal helper to normalize different extent formats to sf

Internal helper to normalize different extent formats to sf

## Usage

``` r
normalize_extent_to_sf(extent, crs = NULL)
```

## Arguments

- extent:

  Spatial extent (numeric vector, sf, or sfc object)

- crs:

  CRS of the extent (required for numeric vectors)

## Value

An sf object with geometry
