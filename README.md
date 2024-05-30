
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

As some functions depend on the [lasR](https://github.com/r-lidar/lasR)
package (version \>= 0.5.6) which is hosted on at
<https://r-lidar.r-universe.dev/lasR> you have to manually install it in
advance with:

``` r
# Install lasR in R:
install.packages("lasR", repos = c("https://r-lidar.r-universe.dev", "https://cran.r-project.org"))
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
#>                                                                                                                               path
#> 1 C:/Users/jwiesehahn/AppData/Local/Temp/Rtmp8ECW6P/temp_libpath2cb015f71aa5/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz
#> 2 C:/Users/jwiesehahn/AppData/Local/Temp/Rtmp8ECW6P/temp_libpath2cb015f71aa5/managelidar/extdata/3dm_32_547_5725_1_ni_20240327.laz
#> 3 C:/Users/jwiesehahn/AppData/Local/Temp/Rtmp8ECW6P/temp_libpath2cb015f71aa5/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz
#> 4 C:/Users/jwiesehahn/AppData/Local/Temp/Rtmp8ECW6P/temp_libpath2cb015f71aa5/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz
#>     minx    miny     maxx    maxy
#> 1 547690 5724000 547999.7 5725000
#> 2 547648 5725000 547998.1 5725991
#> 3 548000 5724000 548992.0 5724997
#> 4 548000 5725000 548995.4 5725992
```
