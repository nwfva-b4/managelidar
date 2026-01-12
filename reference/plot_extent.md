# Plot the spatial extent of LAS files

`plot_extent()` visualizes the spatial extent of LAS/LAZ/COPC files on
an interactive map using bounding boxes derived from file headers or an
existing Virtual Point Cloud (VPC).

## Usage

``` r
plot_extent(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path(s) to LAS/LAZ/COPC files, a directory containing such
  files, or a Virtual Point Cloud (.vpc).

## Value

An interactive `mapview` map displayed in the viewer.

## Examples

``` r
f <- system.file("extdata", package = "managelidar")
plot_extent(f)
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
