# Check whether an EPSG code is valid

Validates an EPSG code by checking it is non-missing, non-zero, and
recognised by
[`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html).
Codes that parse without error but resolve to an unknown CRS (e.g.
32767, "user-defined") are also treated as invalid.

## Usage

``` r
is_valid_crs(epsg_code)
```

## Arguments

- epsg_code:

  Integer. EPSG code to validate.

## Value

Logical scalar: `TRUE` if the code is a recognised CRS, `FALSE`
otherwise.
