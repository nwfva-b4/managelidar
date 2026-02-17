# How to use the functions

## About

This package provides some helper functions to conveniently change or
extract metadata from laz files. It makes use of the `lidR` and `lasR`
packages.

``` r
library(managelidar)
```

## Plot extent

Use the function
[`plot_extent()`](https://wiesehahn.github.io/managelidar/reference/plot_extent.md)
to plot the bounding boxes of all laz files in the folder on top of an
interactive map (using the `mapview` package).

``` r
f <- system.file("extdata", package="managelidar")
plot_extent(f)
```

## Get density

Use the function
[`get_density()`](https://wiesehahn.github.io/managelidar/reference/get_density.md)
to extract the approximate pulse density (first/last-return only) of laz
files. For this function only the header from lasfiles is read and
density is calculated from the bounding box of the data file and the
number of first-returns. This does not take into account if parts of the
bounding box is missing data, and hence this density does not reflect
the density as it is calculates by e.g. `lidR`. However, it is much
faster because it does not read the entire file and density should be
approximately the same if the entire bounding box has point data.

``` r
f <- system.file("extdata", package="managelidar")
get_density(f)
#>                             filename npoints npulses     area pointdensity
#>                               <char>   <int>   <int>    <num>        <num>
#> 1: 3dm_32_547_5724_1_ni_20240327.laz    2936    2606 309656.1  0.009481486
#> 2: 3dm_32_547_5725_1_ni_20240327.laz    3369    1340 347095.0  0.009706277
#> 3: 3dm_32_548_5724_1_ni_20240327.laz   10000    3426 988760.1  0.010113677
#> 4: 3dm_32_548_5725_1_ni_20230904.laz   10000    3854 986554.5  0.010136287
#> 5: 3dm_32_548_5725_1_ni_20240327.laz   10000    4247 987443.7  0.010127160
#>    pulsedensity
#>           <num>
#> 1:  0.008415787
#> 2:  0.003860615
#> 3:  0.003464946
#> 4:  0.003906525
#> 5:  0.004301005
```
