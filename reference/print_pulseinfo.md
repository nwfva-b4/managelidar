# Print summary information about pulse density and penetration ratio

`print_pulseinfo()` computes and prints summary statistics of LiDAR
pulse density, point density, and penetration rates (single vs. multiple
returns).

## Usage

``` r
print_pulseinfo(path)
```

## Arguments

- path:

  The path to a LASfile (.las/.laz/.copc), to a directory which contains
  LASfiles, or to a Virtual Point Cloud (.vpc) referencing LASfiles.

## Value

Invisibly returns `NULL`. The function is called for its side effect of
printing to the console.

## Details

The function uses
[`get_density()`](https://wiesehahn.github.io/managelidar/reference/get_density.md)
to calculate average pulse and point densities, and
[`get_penetration()`](https://wiesehahn.github.io/managelidar/reference/get_penetration.md)
to compute average penetration rates for single and multiple returns.

This function is intended for exploratory reporting and prints
aggregated statistics to the console. It does not return values.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> print_pulseinfo()
#> Density (⌀):
#> ----------------
#> Pulse Density : 0 pulses/m²
#> Point Density : 0 points/m²
#> 
#> Pulse Penetration Rate (⌀):
#> ----------------
#> Single Returns   : 64.5 %
#> Multiple Returns : 35.5 %
#>   Two Returns    : -8.3 %
#>   Three Returns  : 10.8 %
#>   Four Returns   : 23 %
#>   Five Returns   : 9.7 %
#>   Six Returns    : 0.3 %
```
