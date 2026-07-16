# Normalize a links structure into a plain list of link objects

yyjsonr represents an array of link objects as a data frame when read
from disk, filling any field missing on a given link (e.g. `title`) with
an explicit `NULL` (per `df_missing_list_elem = "null"`). Serializing
that data frame back out would emit those as literal `"title": null`,
which is invalid for a STAC link (`title` must be a string or absent).
This function converts either representation into a uniform list of
named lists, dropping NA/NULL optional fields entirely so a link is
either a proper string or not present in the output at all.

## Usage

``` r
normalize_links(links)
```

## Arguments

- links:

  Links as returned by
  [`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
  (data frame) or already a list of link objects

## Value

List of link objects (named lists), never containing NA/NULL field
values
