# managelidar

The goal of managelidar is to facilitate the handling and management of
lidar data files (`*.las/laz/copc`). Its’s main purpose is to convert
new incoming data to data with certain quality standards. Further, it
provides functions to facilitate the quality check of incoming ALS data.
`managelidar` builds on top of R-packages
{[lidR](https://github.com/r-lidar/lidR)} and
{[lasR](https://github.com/r-lidar/lasR)}. It is designed to work with
any number and combination of folders, LASfiles and Virtual Point Clouds
(VPC) and to read as little data as necessary. Most functions read
metadata from VPCs which are efficiently created by lasR in the
background if necessary. If this is not possible metadata is read from
LASheaders via lidR which is a little slower but still pretty fast. Only
some functions
(e.g. [`get_summary()`](https://wiesehahn.github.io/managelidar/reference/get_summary.md))
require actual point cloud data to be read, this may take much longer.
To enhance processing speed the functions run in parallel (via
{[mirai](https://github.com/r-lib/mirai)}) if they are applied on a
larger collection of files.

## Installation

You can install the development version of
{[managelidar](https://github.com/nwfva-b4/managelidar)} from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("nwfva-b4/managelidar")
```

Most functions depend on the {[lasR](https://github.com/r-lidar/lasR)}
package (version \>= 0.14.1) which is hosted at
<https://r-lidar.r-universe.dev/lasR>. As it is not available via CRAN
you have to manually install it in advance with:

``` r
# Install lasR in R:
install.packages("lasR", repos = c("https://r-lidar.r-universe.dev", "https://cran.r-project.org"))
```

## Example

Just some basic examples for package usage.

``` r
library(managelidar)

# create various valid input paths
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
las_file <- list.files(folder, full.names = T, pattern = "*20230904.laz")
vpc_file <- system.file("extdata/sample.vpc", package = "managelidar")
vpc_obj <- yyjsonr::read_json_file(vpc_file)
mixed <- c(folder, las_file)

paths <- list(folder, las_files, las_file, vpc_file, vpc_obj, mixed)


# get the Coordinate Reference System for all types of input
lapply(paths, get_crs)
#> [[1]]
#>                            filename   crs
#> 1 3dm_32_547_5724_1_ni_20240327.laz 25832
#> 2 3dm_32_547_5725_1_ni_20240327.laz 25832
#> 3 3dm_32_548_5724_1_ni_20240327.laz 25832
#> 4 3dm_32_548_5725_1_ni_20230904.laz 25832
#> 5 3dm_32_548_5725_1_ni_20240327.laz 25832
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
#> 1 3dm_32_548_5725_1_ni_20230904.laz 25832
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
#> 4 3dm_32_548_5725_1_ni_20230904.laz 25832
#> 5 3dm_32_548_5725_1_ni_20240327.laz 25832

# get the extent (bbox) from LASfiles
get_spatial_extent(las_files)
#> Get spatial extent
#>   ▼ 4 LASfiles
#>   Overall extent: 547647.97, 5724000.00, 548995.44, 5725991.98  (xmin, ymin, xmax, ymax; EPSG:25832)
#>                            filename   xmin    ymin     xmax    ymax
#> 1 3dm_32_547_5724_1_ni_20240327.laz 547690 5724000 547999.7 5725000
#> 2 3dm_32_547_5725_1_ni_20240327.laz 547648 5725000 547998.1 5725991
#> 3 3dm_32_548_5724_1_ni_20240327.laz 548000 5724000 548992.0 5724997
#> 4 3dm_32_548_5725_1_ni_20240327.laz 548000 5725000 548995.4 5725992

# get names of files intersecting an extent
las_files |>
  filter_spatial(c(547900, 5724900, 548100, 5724900)) |>
  get_names()
#> Filter spatial extent
#>   ▼ 4 LASfiles
#>   ▼ 2 LASfiles retained
#> [1] "3dm_32_547_5724_1_ni_20240327.laz" "3dm_32_548_5724_1_ni_20240327.laz"

# combine with temporal filter on multi-temporal data
c(las_files, las_file) |>
  filter_temporal("2024-03") |>
  filter_spatial(c(547900, 5724900, 548100, 5724900)) |>
  get_names()
#> Filter temporal extent
#>   ▼ 5 LASfiles (2023-09-05 to 2024-03-27)
#>   ▼ 4 LASfiles retained (2024-03-27)
#> Filter spatial extent
#>   ▼ 4 LASfiles
#>   ▼ 2 LASfiles retained
#> [1] "3dm_32_547_5724_1_ni_20240327.laz" "3dm_32_548_5724_1_ni_20240327.laz"
```
