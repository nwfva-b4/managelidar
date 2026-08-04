# Assemble a filename following the NWFVA standard

Pure filename assembly (no I/O):
`region_platform_year_campaign_product_x_y.ext`.

## Usage

``` r
nwfva_filename(region, platform, year, campaign, product, x, y, ext)
```

## Arguments

- region:

  Character. Two-letter region code.

- platform:

  Character. Platform token (e.g. `"als"`).

- year:

  Character. Acquisition year.

- campaign:

  Character. `surveyarea_contractor` campaign label.

- product:

  Character. Data-product token (e.g. `"punktwolke"`).

- x, y:

  Numeric. Lower-left tile corner coordinates, in full meters, snapped
  to the 1000m tile grid (i.e. `minx`/`miny` from
  [`resolve_naming_components()`](https://wiesehahn.github.io/managelidar/reference/resolve_naming_components.md)
  multiplied by 1000).

- ext:

  Character. File extension (without leading dot).

## Value

Character vector of assembled filenames.
