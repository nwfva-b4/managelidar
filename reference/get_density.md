# Get approximate point and pulse density of LAS files

`get_density()` calculates the approximate average point and pulse
density of LAS files.

## Usage

``` r
get_density(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing LAS
  files, or a Virtual Point Cloud (.vpc) referencing these files.

- full.names:

  Logical. If `TRUE`, filenames in the output are full paths; otherwise
  base filenames (default).

## Value

A `data.frame` with columns:

- filename:

  File name or path.

- npoints:

  Total number of points in the file.

- npulses:

  Number of first-return pulses.

- area:

  Area of bounding box (units of CRS^2).

- pointdensity:

  Approximate points per unit area.

- pulsedensity:

  Approximate first-return pulses per unit area.

## Details

Only the LAS file headers are read. Densities are calculated based on
the bounding box and number of points / first-return pulses. This does
not account for missing data within the bounding box, so the density is
approximate and faster to compute than reading the full point cloud.

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
get_density(f)
#>                             filename npoints npulses     area pointdensity
#>                               <char>   <int>   <int>    <num>        <num>
#> 1: 3dm_32_547_5724_1_ni_20240327.laz    2936    2606 309656.1  0.009481486
#> 2: 3dm_32_547_5725_1_ni_20240327.laz    3369    1340 347095.0  0.009706277
#> 3: 3dm_32_548_5724_1_ni_20240327.laz   10000    3426 988760.1  0.010113677
#> 4: 3dm_32_548_5725_1_ni_20240327.laz   10000    4247 987443.7  0.010127160
#>    pulsedensity
#>           <num>
#> 1:  0.008415787
#> 2:  0.003860615
#> 3:  0.003464946
#> 4:  0.004301005
```
