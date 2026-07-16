# Internal helper to parse datetime input

Internal helper to parse datetime input

## Usage

``` r
parse_datetime_input(dt, position = "start")
```

## Arguments

- dt:

  POSIXct, Date, or character datetime

- position:

  Either "start" or "end" - determines whether to use beginning or end
  of period

## Value

POSIXct object in UTC
