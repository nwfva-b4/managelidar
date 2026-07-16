# Flatten any list-columns in a data frame / sf object to JSON text

Leaves the geometry column (and any plain atomic column) untouched;
every other list-column gets serialized element-wise to a JSON string,
with `NULL`/length-zero entries becoming `NA`.

## Usage

``` r
flatten_list_columns(df)
```

## Arguments

- df:

  A data frame or sf object

## Value

The same object with list-columns replaced by character columns
