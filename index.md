# managelidar

The goal of managelidar is to facilitate the handling and management of
lidar data files (`*.las/laz/copc`). Its’s main purpose is to convert
new incoming data to data with certain quality standards. Further, it
provides functions to facilitate the quality check of incoming ALS data.
`managelidar` builds on top of R-packages {lidR} and {lasR}. It is
designed to work with any number and combination of folders, LASfiles,
and Virtual Point CLouds (VPC) and to read as little data as necessary.
Most functions read metadata from VPCs which are efficiently created by
lasR in the background if necessary. If this is not possible metadata is
read from LASheaders via lidR which is a little slower but still pretty
fast. Only some functions (e.g. summarise) require actual point cloud
data to be read, this may take much longer. To enhance processing speed
the functions run in parallel (via {mirai}) if they are applied on a
larger collection of files.

## Installation

You can install the development version of managelidar from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("nwfva-b4/managelidar")
```

Some functions depend on the [lasR](https://github.com/r-lidar/lasR)
package (version \>= 0.14.1) which is hosted at
<https://r-lidar.r-universe.dev/lasR>, you have to manually install it
in advance with:

``` r
# Install lasR in R:
install.packages("lasR", repos = c("https://r-lidar.r-universe.dev", "https://cran.r-project.org"))
```

## Example

Just some basic examples for package usage.

``` r
library(managelidar)

folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*.laz")
las_file <- las_files[1] 
vpc_file <- tempfile(fileext = ".vpc"); lasR::exec(lasR::write_vpc(vpc_file, absolute_path = TRUE), on = las_files)
#> [1] "C:\\Users\\JWIESE~1\\AppData\\Local\\Temp\\RtmpwZy829\\file3c302dd1b25.vpc"
vpc_obj <- yyjsonr::read_json_file(vpc_file)
mixed <- c(folder, las_file)

paths <- list(folder, las_files, las_file, vpc_file, vpc_obj, mixed)  

# get the Coordinate reference system for all types of input
lapply(paths, get_crs)
#> [[1]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832
#> 
#> [[2]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832
#> 
#> [[3]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 
#> [[4]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832
#> 
#> [[5]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832
#> 
#> [[6]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20240327.laz 25832

# get the extent (bbox) from LASfiles
get_extent(las_files)
#>                            filename   xmin    ymin     xmax    ymax
#> 1 3dm_32_547_5724_1_ni_20240327.laz 547690 5724000 547999.7 5725000
#> 2 3dm_32_547_5725_1_ni_20240327.laz 547648 5725000 547998.1 5725991
#> 3 3dm_32_548_5724_1_ni_20240327.laz 548000 5724000 548992.0 5724997
#> 4 3dm_32_548_5725_1_ni_20240327.laz 548000 5725000 548995.4 5725992
```
