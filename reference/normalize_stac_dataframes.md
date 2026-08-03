# Recursively convert any data.frame in a STAC-ish object into a plain list of per-row objects

yyjsonr represents a JSON array of uniformly-shaped objects (`links`,
`providers`, ...) as a data.frame when read back from disk, while the
same field built fresh in memory is a plain list of named lists (e.g.
`list(list(name = ..., roles = ...), list(name = ..., roles = ...))`).
`links` is normalized back to a plain list explicitly in
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
(because the package's own link-handling code iterates over it), but any
*other* uniformly-shaped array field - `providers` being the case that
surfaced this - would otherwise never compare equal to its own disk-read
version, in
[`write_stac_if_changed()`](https://wiesehahn.github.io/managelidar/reference/write_stac_if_changed.md),
regardless of which side happens to be which representation.

## Usage

``` r
normalize_stac_dataframes(x)
```

## Arguments

- x:

  Any R object (typically a STAC list structure)

## Value

The same structure with every data.frame replaced by an equivalent list
of per-row objects
