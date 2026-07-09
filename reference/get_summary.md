# Compute summary metrics for individual LASfiles

`get_summary()` calculates standard summary metrics for LASfiles,
including:

- Temporal metrics (`t_min`, `t_median`, `t_max`)

- Intensity metrics (`i_min`, `i_mean`, `i_median`, `i_max`, `i_p5`,
  `i_p95`, `i_sd`)

- Elevation metrics (`z_min`, `z_median`, `z_max`)

- Histograms (`i_histogram`, `z_histogram`) if `iwbin` and `zwbin` are
  greater than 0

- Point counts and classifications (`npoints`, `nsingle`, `nwithheld`,
  `nsynthetic`, `npoints_per_return`, `npoints_per_class`)

- Coordinate system (`epsg`)

## Usage

``` r
get_summary(
  path,
  out_dir = NULL,
  full.names = FALSE,
  samplebased = FALSE,
  zwbin = 10,
  iwbin = 100,
  metrics = c("t_min", "t_median", "t_max", "i_min", "i_mean", "i_median", "i_max",
    "i_p5", "i_p95", "i_sd", "z_min", "z_median", "z_max")
)
```

## Arguments

- path:

  Path to a LAS/LAZ/COPC file, a directory, or a Virtual Point Cloud
  (.vpc) file.

- out_dir:

  Optional directory to save JSON summaries. If not set, the function
  returns a named list instead.

- full.names:

  Logical. If `TRUE`, the returned list is named with full paths;
  otherwise, basenames are used.

- samplebased:

  Logical. If `TRUE`, reads only a spatial subsample of each file
  (faster for large files).

- zwbin:

  Numeric. Bin width (meters) for elevation histogram (`z_histogram`).
  Set `0` to skip `z_histogram`.

- iwbin:

  Numeric. Bin width (intensity units) for intensity histogram
  (`i_histogram`). Set `0` to skip `i_histogram`.

- metrics:

  Character vector of metrics to compute. Defaults to:
  `c("t_min", "t_median", "t_max", "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd", "z_min", "z_median", "z_max")`.

## Value

If `out_dir` is not set, returns a named list, one element per LASfile.
Each element is a list containing:

- npoints:

  Total number of points

- nsingle:

  Number of single-return points

- nwithheld:

  Number of withheld points

- nsynthetic:

  Number of synthetic points

- npoints_per_return:

  Named vector of counts per return number

- npoints_per_class:

  Named vector of counts per classification code

- z_histogram:

  Elevation histogram (if `zwbin > 0`)

- i_histogram:

  Intensity histogram (if `iwbin > 0`)

- epsg:

  EPSG code of the LASfile CRS

- metrics:

  List of calculated summary metrics, e.g., min, median, max for time,
  intensity, and elevation

If `out_dir` is set, the function returns `NULL` invisibly after writing
JSON files.

## Details

Results can optionally be saved as JSON files per LASfile.

In comparison to
[`lasR::summarise`](https://rdrr.io/pkg/lasR/man/summarise.html) this
function returns individual summaries per file instead of an aggregated
summary among all files. If `out_dir` is provided, a JSON file is
created for each LASfile, with the same name but `.json` extension.
Existing JSON files are skipped automatically. If `out_dir` is not
provided, the function returns a named list where each element
corresponds to a LASfile.

Setting `iwbin = 0` or `zwbin = 0` disables calculation of intensity or
elevation histograms, which can save time and memory for large datasets.

Parallel processing is used automatically for large numbers of files
through
[`map_las()`](https://wiesehahn.github.io/managelidar/reference/map_las.md).

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_summary()
#> $`3dm_32_547_5724_1_ni_20240327.laz`
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints
#> [1] 2936
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$nsingle
#> [1] 2605
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$nwithheld
#> [1] 0
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$nsynthetic
#> [1] 0
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`1`
#> [1] 2606
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`2`
#> [1] 127
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`3`
#> [1] 127
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`4`
#> [1] 63
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`5`
#> [1] 12
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_return$`6`
#> [1] 1
#> 
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`2`
#> [1] 1781
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`3`
#> [1] 269
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`4`
#> [1] 9
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`5`
#> [1] 3
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`7`
#> [1] 2
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$npoints_per_class$`12`
#> [1] 872
#> 
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`220.000000`
#> [1] 42
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`230.000000`
#> [1] 153
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`240.000000`
#> [1] 255
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`250.000000`
#> [1] 499
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`260.000000`
#> [1] 527
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`270.000000`
#> [1] 260
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`280.000000`
#> [1] 365
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`290.000000`
#> [1] 452
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`300.000000`
#> [1] 272
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$z_histogram$`310.000000`
#> [1] 111
#> 
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`100.000000`
#> [1] 12
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`200.000000`
#> [1] 23
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`300.000000`
#> [1] 15
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`400.000000`
#> [1] 12
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`500.000000`
#> [1] 18
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`600.000000`
#> [1] 11
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`700.000000`
#> [1] 20
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`800.000000`
#> [1] 16
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`900.000000`
#> [1] 19
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1000.000000`
#> [1] 23
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1100.000000`
#> [1] 43
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1200.000000`
#> [1] 170
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1300.000000`
#> [1] 504
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1400.000000`
#> [1] 611
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1500.000000`
#> [1] 733
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1600.000000`
#> [1] 557
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1700.000000`
#> [1] 147
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$i_histogram$`1800.000000`
#> [1] 2
#> 
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$epsg
#> [1] 25832
#> 
#> $`3dm_32_547_5724_1_ni_20240327.laz`$metrics
#>   i_max   i_mean i_median i_min    i_p5 i_p95     i_sd     t_max  t_median
#> 1  1852 1446.975     1495   105 1014.25  1700 251.1633 395563360 395563168
#>       t_min   z_max z_median   z_min
#> 1 395562976 316.283 269.6005 222.866
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints
#> [1] 3369
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$nsingle
#> [1] 1337
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$nwithheld
#> [1] 0
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$nsynthetic
#> [1] 0
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`1`
#> [1] 1340
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`2`
#> [1] 534
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`3`
#> [1] 748
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`4`
#> [1] 584
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`5`
#> [1] 162
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_return$`6`
#> [1] 1
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`1`
#> [1] 1
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`2`
#> [1] 1480
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`3`
#> [1] 52
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`4`
#> [1] 12
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`5`
#> [1] 3
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`7`
#> [1] 1
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`9`
#> [1] 5
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$npoints_per_class$`12`
#> [1] 1815
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`220.000000`
#> [1] 141
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`230.000000`
#> [1] 454
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`240.000000`
#> [1] 487
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`250.000000`
#> [1] 395
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`260.000000`
#> [1] 415
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`270.000000`
#> [1] 526
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`280.000000`
#> [1] 506
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`290.000000`
#> [1] 244
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`300.000000`
#> [1] 155
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$z_histogram$`310.000000`
#> [1] 46
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`0.000000`
#> [1] 2
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`100.000000`
#> [1] 25
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`200.000000`
#> [1] 77
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`300.000000`
#> [1] 58
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`400.000000`
#> [1] 65
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`500.000000`
#> [1] 77
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`600.000000`
#> [1] 62
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`700.000000`
#> [1] 84
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`800.000000`
#> [1] 115
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`900.000000`
#> [1] 125
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1000.000000`
#> [1] 192
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1100.000000`
#> [1] 220
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1200.000000`
#> [1] 235
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1300.000000`
#> [1] 344
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1400.000000`
#> [1] 442
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1500.000000`
#> [1] 706
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1600.000000`
#> [1] 455
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1700.000000`
#> [1] 82
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$i_histogram$`1800.000000`
#> [1] 3
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$epsg
#> [1] 25832
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`$metrics
#>   i_max   i_mean i_median i_min     i_p5 i_p95     i_sd     t_max  t_median
#> 1  1845 1269.536     1400    80 414.0001  1667 382.8976 395563552 395563360
#>       t_min   z_max z_median   z_min
#> 1 395563136 316.526  264.854 223.448
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints
#> [1] 10000
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$nsingle
#> [1] 3418
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$nwithheld
#> [1] 0
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$nsynthetic
#> [1] 0
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`1`
#> [1] 3426
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`2`
#> [1] 1998
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`3`
#> [1] 2228
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`4`
#> [1] 1755
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`5`
#> [1] 558
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`6`
#> [1] 33
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_return$`7`
#> [1] 2
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`1`
#> [1] 3
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`2`
#> [1] 5318
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`3`
#> [1] 520
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`4`
#> [1] 83
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`5`
#> [1] 19
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`7`
#> [1] 4
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$npoints_per_class$`12`
#> [1] 4053
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`220.000000`
#> [1] 9
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`230.000000`
#> [1] 80
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`240.000000`
#> [1] 249
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`250.000000`
#> [1] 425
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`260.000000`
#> [1] 666
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`270.000000`
#> [1] 805
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`280.000000`
#> [1] 1011
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`290.000000`
#> [1] 1169
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`300.000000`
#> [1] 1227
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`310.000000`
#> [1] 1484
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`320.000000`
#> [1] 1294
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`330.000000`
#> [1] 628
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`340.000000`
#> [1] 448
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`350.000000`
#> [1] 344
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`360.000000`
#> [1] 147
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$z_histogram$`370.000000`
#> [1] 14
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`0.000000`
#> [1] 1
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`100.000000`
#> [1] 64
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`200.000000`
#> [1] 163
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`300.000000`
#> [1] 123
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`400.000000`
#> [1] 153
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`500.000000`
#> [1] 156
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`600.000000`
#> [1] 187
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`700.000000`
#> [1] 220
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`800.000000`
#> [1] 256
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`900.000000`
#> [1] 299
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1000.000000`
#> [1] 478
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1100.000000`
#> [1] 577
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1200.000000`
#> [1] 795
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1300.000000`
#> [1] 1104
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1400.000000`
#> [1] 1413
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1500.000000`
#> [1] 1690
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1600.000000`
#> [1] 1349
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1700.000000`
#> [1] 813
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1800.000000`
#> [1] 156
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$i_histogram$`1900.000000`
#> [1] 3
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$epsg
#> [1] 25832
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`$metrics
#>   i_max   i_mean i_median i_min i_p5 i_p95     i_sd     t_max  t_median
#> 1  1956 1328.449     1432    93  498  1743 368.4554 395563776 395563360
#>       t_min   z_max z_median   z_min
#> 1 395562976 372.281 304.8415 224.578
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints
#> [1] 10000
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$nsingle
#> [1] 4241
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$nwithheld
#> [1] 0
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$nsynthetic
#> [1] 0
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`1`
#> [1] 4247
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`2`
#> [1] 1657
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`3`
#> [1] 2105
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`4`
#> [1] 1482
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`5`
#> [1] 489
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`6`
#> [1] 17
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`7`
#> [1] 2
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_return$`8`
#> [1] 1
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`1`
#> [1] 2
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`2`
#> [1] 5622
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`3`
#> [1] 282
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`4`
#> [1] 66
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`5`
#> [1] 12
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`7`
#> [1] 1
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`9`
#> [1] 17
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$npoints_per_class$`12`
#> [1] 3998
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`230.000000`
#> [1] 148
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`240.000000`
#> [1] 514
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`250.000000`
#> [1] 940
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`260.000000`
#> [1] 1269
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`270.000000`
#> [1] 1270
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`280.000000`
#> [1] 1404
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`290.000000`
#> [1] 1162
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`300.000000`
#> [1] 780
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`310.000000`
#> [1] 543
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`320.000000`
#> [1] 408
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`330.000000`
#> [1] 363
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`340.000000`
#> [1] 291
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`350.000000`
#> [1] 260
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`360.000000`
#> [1] 263
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`370.000000`
#> [1] 250
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$z_histogram$`380.000000`
#> [1] 135
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`0.000000`
#> [1] 1
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`100.000000`
#> [1] 64
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`200.000000`
#> [1] 187
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`300.000000`
#> [1] 145
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`400.000000`
#> [1] 200
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`500.000000`
#> [1] 176
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`600.000000`
#> [1] 216
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`700.000000`
#> [1] 209
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`800.000000`
#> [1] 248
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`900.000000`
#> [1] 308
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1000.000000`
#> [1] 392
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1100.000000`
#> [1] 503
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1200.000000`
#> [1] 646
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1300.000000`
#> [1] 938
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1400.000000`
#> [1] 1363
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1500.000000`
#> [1] 1872
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1600.000000`
#> [1] 1896
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1700.000000`
#> [1] 559
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1800.000000`
#> [1] 75
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$i_histogram$`1900.000000`
#> [1] 2
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$epsg
#> [1] 25832
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`$metrics
#>   i_max   i_mean i_median i_min i_p5 i_p95     i_sd     t_max  t_median
#> 1  1919 1327.791     1466    98  452  1712 381.2701 395564064 395563552
#>       t_min   z_max z_median   z_min
#> 1 395563360 385.486 286.6505 232.946
#> 
#> 
```
