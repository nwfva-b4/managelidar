# Compute summary metrics for individual LAS files and optionally save as JSON

`get_summary()` calculates standard summary metrics for LAS files,
including:

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

If `out_dir` is not set, returns a named list, one element per LAS file.
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

  EPSG code of the LAS file CRS

- metrics:

  List of calculated summary metrics, e.g., min, median, max for time,
  intensity, and elevation

If `out_dir` is set, the function returns `NULL` invisibly after writing
JSON files.

## Details

- Temporal metrics (`t_min`, `t_median`, `t_max`)

- Intensity metrics (`i_min`, `i_mean`, `i_median`, `i_max`, `i_p5`,
  `i_p95`, `i_sd`)

- Elevation metrics (`z_min`, `z_median`, `z_max`)

- Histograms (`i_histogram`, `z_histogram`) if `iwbin` and `zwbin` are
  greater than 0

- Point counts and classifications (`npoints`, `nsingle`, `nwithheld`,
  `nsynthetic`, `npoints_per_return`, `npoints_per_class`)

- Coordinate system (`epsg`)

Results can optionally be saved as JSON files per LAS file.

In comparison to `lasR::summarise` this function returns individual
summaries per file instead of an aggregated summary among all files. If
`out_dir` is provided, a JSON file is created for each LAS file, with
the same name but `.json` extension. Existing JSON files are skipped
automatically. If `out_dir` is not provided, the function returns a
named list where each element corresponds to a LAS file.

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
#> ERROR processing 3dm_32_547_5724_1_ni_20240327.laz: there is no package called ‘lasR’
#> ERROR processing 3dm_32_547_5725_1_ni_20240327.laz: there is no package called ‘lasR’
#> ERROR processing 3dm_32_548_5724_1_ni_20240327.laz: there is no package called ‘lasR’
#> ERROR processing 3dm_32_548_5725_1_ni_20240327.laz: there is no package called ‘lasR’
#> $`3dm_32_547_5724_1_ni_20240327.laz`
#> $`3dm_32_547_5724_1_ni_20240327.laz`$error
#> [1] "there is no package called ‘lasR’"
#> 
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`
#> $`3dm_32_547_5725_1_ni_20240327.laz`$error
#> [1] "there is no package called ‘lasR’"
#> 
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`
#> $`3dm_32_548_5724_1_ni_20240327.laz`$error
#> [1] "there is no package called ‘lasR’"
#> 
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`
#> $`3dm_32_548_5725_1_ni_20240327.laz`$error
#> [1] "there is no package called ‘lasR’"
#> 
#> 
```
