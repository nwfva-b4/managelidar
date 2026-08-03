# Offset between LAS-stored "Adjusted Standard GPS Time" and true GPS time

Per the ASPRS LAS specification, files using Adjusted Standard GPS Time
store `GPS Time - 1,000,000,000`; this constant converts back.

## Usage

``` r
LAS_ADJUSTED_GPSTIME_OFFSET
```

## Format

An object of class `numeric` of length 1.
