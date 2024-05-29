
<!-- README.md is generated from README.Rmd. Please edit that file -->

# managelidar

<!-- badges: start -->
<!-- badges: end -->

The goal of managelidar is to facilitate the handling and management of
lidar data files (`*.laz`).

## Installation

You can install the development version of managelidar from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("wiesehahn/managelidar")
```

## Example

This is a basic function which queries the spatial extents of all lidar
data files (`*.laz`) in a given folder from its data headers (without
reading the actual point cloud data). It returns a dataframe which can
be used in further data management steps.

``` r
library(managelidar)
f <- system.file("extdata", package="managelidar")
get_extent(f)
#>                                                                                                                                path
#> 1 C:/Users/jwiesehahn/AppData/Local/Temp/RtmpuE58vp/temp_libpath1320c2e594a15/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz
#> 2 C:/Users/jwiesehahn/AppData/Local/Temp/RtmpuE58vp/temp_libpath1320c2e594a15/managelidar/extdata/3dm_32_547_5725_1_ni_20240327.laz
#> 3 C:/Users/jwiesehahn/AppData/Local/Temp/RtmpuE58vp/temp_libpath1320c2e594a15/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz
#> 4 C:/Users/jwiesehahn/AppData/Local/Temp/RtmpuE58vp/temp_libpath1320c2e594a15/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz
#>       minx    miny     maxx    maxy
#> 1 547690.0 5724000 547999.9 5725000
#> 2 547647.5 5725000 548000.0 5726000
#> 3 548000.0 5724000 549000.0 5725000
#> 4 548000.0 5725000 549000.0 5726000
```
