# Compute pulse penetration ratios from LAS headers

`get_penetration()` computes approximate pulse penetration ratios for
LAS/LAZ/COPC files using information stored in the LASfile header. Only
header data are read; point data are not loaded.

## Usage

``` r
get_penetration(path, full.names = FALSE)
```

## Arguments

- path:

  Character vector specifying one or more paths to:

  - LAS/LAZ/COPC files

  - Directories containing LAS/LAZ/COPC files (non-recursive)

  - Virtual Point Cloud files (`.vpc`) referencing LASfiles

- full.names:

  Logical. If `TRUE`, return full file paths in the `filename` column.
  If `FALSE` (default), only the base file names are returned.

## Value

A `data.frame` with one row per input file and the following columns:

- filename:

  File name or full path of the LASfile

- single:

  Proportion of pulses with exactly one return

- two:

  Proportion of pulses with exactly two returns

- three:

  Proportion of pulses with exactly three returns

- four:

  Proportion of pulses with exactly four returns

- five:

  Proportion of pulses with exactly five returns

- six:

  Proportion of pulses with exactly six returns

- multiple:

  Proportion of pulses with two or more returns

## Details

The function estimates the proportion of pulses that resulted in exactly
one return, two returns, three returns, up to six returns, as well as
the proportion of pulses with multiple returns (two or more).

Pulse penetration ratios are derived from the “Number of points by
return” field in the LAS header. Because only header information is
used, results are approximate.

For small files or spatially clipped tiles, pulses may be split at tile
boundaries, which can lead to biased penetration ratios. Consequently,
values should be interpreted as indicative rather than exact.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_penetration()
#>                             filename single    two three  four  five   six
#>                               <char>  <num>  <num> <num> <num> <num> <num>
#> 1: 3dm_32_547_5724_1_ni_20240327.laz  0.951  0.000 0.025 0.020 0.004 0.000
#> 2: 3dm_32_547_5725_1_ni_20240327.laz  0.601 -0.160 0.122 0.315 0.120 0.001
#> 3: 3dm_32_548_5724_1_ni_20240327.laz  0.417 -0.067 0.138 0.349 0.153 0.009
#> 4: 3dm_32_548_5725_1_ni_20240327.laz  0.610 -0.105 0.147 0.234 0.111 0.004
#>    multiple
#>       <num>
#> 1:    0.049
#> 2:    0.399
#> 3:    0.583
#> 4:    0.390
```
