# managelidar

**managelidar** is a LiDAR catalog processing engine for R that builds
on top of {[lasR](https://github.com/r-lidar/lasR)}. While lasR
efficiently handles individual LASfile processing, managelidar adds
catalog-level capabilities through Virtual Point Cloud (VPC) files,
enabling fast metadata operations across entire collections without
reading point cloud data. Although most functions can be used on any
LASdata it was designed primarily to work with data from Germany
according to [AdV
Standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/1593R3%20PQS%203D-Messdaten560c.pdf?imgUid=f663acb8-b78b-6919-fb68-66101ffcef97&uBasVariant=11111111-1111-1111-1111-111111111111).

## Key Features

- **VPC-based catalog management**: Work with collections of
  LAS/LAZ/COPC files efficiently
- **Flexible input handling**: Process any combination of folders,
  individual files, VPC files, or VPC objects
- **Metadata-first approach**: Most operations read only file headers or
  VPC metadata, not point data
- **Parallel processing**: Automatic parallelization via
  {[mirai](https://github.com/r-lib/mirai)} for large collections
- **Quality assurance pipeline**: Convert raw ALS data to standardized,
  quality-controlled outputs
- **STAC-compliant VPCs**: Create enriched Virtual Point Clouds
  following STAC specifications

## Main Workflows

### 1. Catalog Exploration

Query and filter LiDAR collections without reading point data:

``` r
# Get CRS, extents, temporal coverage
get_crs(path)
get_spatial_extent(path)
get_temporal_extent(path)

# Plot extent in viewer
plot_extent(path)

# Filter by space and time
path |>
  filter_spatial(bbox) |>
  filter_temporal("2024-03") |>
  get_names()
```

### 2. Data Processing Pipeline

Convert raw ALS data to standardized format:

``` r
# Process raw files: classify noise, normalize intensity, create metadata, ...
raw_to_processed(
  path = "raw_data/",
  out_dir = "processed/"
)

# Create enriched VPC with STAC-compliant metadata
create_vpc_enriched(
  path = "processed/pointcloud",
  out_file = "processed/collection.vpc"
)
```

### 3. Quality Control

Validate incoming data:

``` r
# Check naming conventions (according to AdV standard)
check_names(path)

# Verify spatial tiling pattern (according to AdV standard)
check_tiling(path)

# Get detailed summaries (reads point data)
get_summary(path)

# Check if data is spatially indexed / classified / multitemporal
is_indexed(path)
is_classified(path)
is_multitemporal(path)
```

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("nwfva-b4/managelidar")
```

**Important:** managelidar requires
{[lasR](https://github.com/r-lidar/lasR)} (version \>= 0.18.0), which is
available on r-universe but not on CRAN. Install it first:

``` r
install.packages("lasR", repos = c("https://r-lidar.r-universe.dev", "https://cran.r-project.org"))
```

## Design Philosophy

managelidar is designed around three core principles:

1.  **Read as little as possible**: VPC files provide fast access to
    metadata without reading point clouds
2.  **Accept any input format**: Functions work seamlessly with folders,
    files, VPCs, or mixed inputs. They are internally resolved as VPC
    (handling duplicates)
3.  **Scale automatically**: Parallel processing kicks in automatically
    for large collections by many functions
4.  **Pipepable**: Output of many functions can be used as input for
    other functions

Most functions follow this pattern: - Create VPC in background if needed
(fast) - Read metadata from VPC (very fast) - Only read point data when
absolutely necessary

## Example Usage

``` r
library(managelidar)

# Create various valid input paths
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")
las_file <- list.files(folder, full.names = TRUE, pattern = "*20230904.laz")
vpc_file <- system.file("extdata/sample.vpc", package = "managelidar")
vpc_obj <- yyjsonr::read_json_file(vpc_file)
mixed <- c(folder, las_file)

paths <- list(folder, las_files, las_file, vpc_file, vpc_obj, mixed)

# Get CRS - works with any input type
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

# Get spatial extent from multiple files
get_spatial_extent(las_files)
#> Get spatial extent
#>   ▼ 4 LASfiles
#>   Overall extent: 547647.97, 5724000.00, 548995.44, 5725991.98  (xmin, ymin, xmax, ymax; EPSG:25832)
#>                            filename   xmin    ymin     xmax    ymax
#> 1 3dm_32_547_5724_1_ni_20240327.laz 547690 5724000 547999.7 5725000
#> 2 3dm_32_547_5725_1_ni_20240327.laz 547648 5725000 547998.1 5725991
#> 3 3dm_32_548_5724_1_ni_20240327.laz 548000 5724000 548992.0 5724997
#> 4 3dm_32_548_5725_1_ni_20240327.laz 548000 5725000 548995.4 5725992

# Filter by spatial extent and get names
las_files |>
  filter_spatial(c(547900, 5724900, 548100, 5724900)) |>
  get_names()
#> Filter spatial extent
#>   ▼ 4 LASfiles
#>   ▼ 2 LASfiles retained
#> [1] "3dm_32_547_5724_1_ni_20240327.laz" "3dm_32_548_5724_1_ni_20240327.laz"

# Combine spatial and temporal filters
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

## Relationship to lasR and lidR

- **lasR**: Efficient point cloud processing engine for individual files
- **managelidar**: Catalog-level operations and VPC management built on
  lasR
- **lidR**: Used for header reading when VPC metadata is unavailable

Think of it as: lasR handles the processing, managelidar handles the
catalog.

## License

## Acknowledgments

Built on the excellent work of the [r-lidar](https://github.com/r-lidar)
ecosystem.
