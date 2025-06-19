
<!-- README.md is generated from README.Rmd. Please edit that file -->

# managelidar

<!-- badges: start -->
<!-- badges: end -->

The goal of managelidar is to facilitate the handling and management of
lidar data files (`*.las/laz`). Its’s main purpose is to convert new
incoming data to data with certain quality standards. Further, it
provides functions to facilitate the quality check of incoming ALS data.
`managelidar` makes use of functions provided by {lidR} and {lasR}. Most
functions which provide information about 3D point cloud files are
working without reading the entire files, as this would require long
computations for large collections of data. Instead, attributes are read
from the file header where possible.

## Installation

You can install the development version of managelidar from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pkg_install("wiesehahn/managelidar")
```

As some functions depend on the [lasR](https://github.com/r-lidar/lasR)
package (version \>= 0.14.1) which is hosted on at
<https://r-lidar.r-universe.dev/lasR>, you have to manually install it
in advance with:

``` r
# Install lasR in R:
install.packages("lasR", repos = c("https://r-lidar.r-universe.dev", "https://cran.r-project.org"))
```

## Example

This is a basic function which queries the spatial extents of all lidar
data files in a given folder from its data headers (without reading the
actual point cloud data). It returns a dataframe which can be used in
further data management steps.

``` r
library(managelidar)
f <- system.file("extdata", package="managelidar")
get_extent(f)
#>                                file   minx    miny    minz     maxx    maxy
#> 1 3dm_32_547_5724_1_ni_20240327.laz 547690 5724000 222.866 547999.7 5725000
#> 2 3dm_32_547_5725_1_ni_20240327.laz 547648 5725000 223.448 547998.1 5725991
#> 3 3dm_32_548_5724_1_ni_20240327.laz 548000 5724000 224.578 548992.0 5724997
#> 4 3dm_32_548_5725_1_ni_20240327.laz 548000 5725000 232.946 548995.4 5725992
#>      maxz
#> 1 316.283
#> 2 316.526
#> 3 372.281
#> 4 385.486
```
