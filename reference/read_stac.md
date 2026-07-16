# Read a STAC JSON file

Links are normalized to a plain list of link objects via
[`normalize_links()`](https://wiesehahn.github.io/managelidar/reference/normalize_links.md),
regardless of yyjsonr's internal data-frame representation. This
prevents optional fields (like `title`) that are absent on some links
from round-tripping back out as explicit `null` values when the object
is later written with
[`write_stac()`](https://wiesehahn.github.io/managelidar/reference/write_stac.md).

## Usage

``` r
read_stac(path)
```

## Arguments

- path:

  Path to STAC JSON file

## Value

List representing STAC object
