# Plot the spatial extent of LASfiles

Visualizes the spatial extent of LAS/LAZ/COPC files on an interactive
map.

## Usage

``` r
plot_extent(path, per_file = TRUE, full.names = FALSE, verbose = TRUE)
```

## Arguments

- path:

  Character. Path(s) to LAS/LAZ/COPC files, a directory, a VPC file, or
  a VPC object already loaded in R.

- per_file:

  Logical. If `TRUE` (default), plots extent per file. If `FALSE`, plots
  combined extent as a single polygon.

- full.names:

  Logical. If `TRUE`, shows full file paths in labels; otherwise shows
  base filenames (default). Only used when `per_file = TRUE`.

- verbose:

  Logical. If `TRUE` (default), prints extent information.

## Value

An interactive `mapview` map displayed in the viewer.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

# Plot extent per file
las_files |> plot_extent()
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Plot combined extent
las_files |> plot_extent(per_file = FALSE)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
