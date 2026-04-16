# Create enriched Virtual Point Cloud with outlines and summary metadata

Creates an enriched VPC from LAS/LAZ/COPC files with detailed outline
geometries and summary statistics.

Creates an enriched VPC from LAS/LAZ/COPC files with detailed outline
geometries and summary statistics.

## Usage

``` r
create_vpc_enriched(
  path,
  outlines = NULL,
  metadata = NULL,
  out_file = NULL,
  verbose = TRUE
)

create_vpc_enriched(
  path,
  outlines = NULL,
  metadata = NULL,
  out_file = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to LAS/LAZ/COPC file(s), directory, VPC file(s), or
  VPC object.

- outlines:

  Character or logical. Directory containing outline GeoJSON files. If
  NULL (default), looks for an 'outlines' directory adjacent to the
  input files. If FALSE, geometry will not be updated from outlines.

- metadata:

  Character or logical. Directory containing summary JSON files. If NULL
  (default), looks for a 'metadata' directory adjacent to the input
  files. If FALSE, metadata properties will not be added.

- out_file:

  Character. Output VPC file path. If NULL (default), returns the
  enriched VPC as an R object.

- verbose:

  Logical. Print progress messages (default: TRUE).

- outline_dir:

  Character. Directory containing outline GeoJSON files. If NULL,
  outlines are computed on-the-fly (requires reading full point clouds).

- metadata_dir:

  Character. Directory containing summary JSON files. If NULL, summaries
  are computed on-the-fly (requires reading full point clouds).

## Value

If `out_file` is NULL, returns the enriched VPC as a list. If `out_file`
is provided, saves to file and returns the file path.

If `out_file` is NULL, returns the enriched VPC as a list. If `out_file`
is provided, saves to file and returns the file path.

## Details

This function enriches VPC features with:

- Detailed outline geometries (WGS84 polygons instead of bounding boxes)

- Point and pulse density statistics

- Per-dimension statistics (Z, Intensity, GpsTime)

- Classification and return number distributions

**Performance Note:** When `outline_dir` or `metadata_dir` are NULL, the
function must read the complete point cloud for each file to compute
outlines and summaries. This is **very slow** for large datasets.

The enriched VPC follows the STAC pointcloud extension specification
with additional custom properties for point and pulse density.

This function is typically used after
[`raw_to_processed`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
to create a collection-level VPC with enhanced metadata.

This function enriches VPC features with:

- Detailed outline geometries (WGS84 polygons instead of bounding boxes)

- Point and pulse density statistics

- Per-dimension statistics (Z, Intensity, GpsTime)

- Classification and return number distributions

**Typical workflow:**

1.  Run
    [`raw_to_processed`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
    to create processed point clouds with outlines and metadata in
    standardized directories

2.  Run `create_vpc_enriched` to create a collection VPC with enhanced
    metadata from those directories

**Auto-detection:** When `outlines` or `metadata` are NULL, the function
looks for directories named 'outlines' and 'metadata' in the parent
directory of the input files (as created by
[`raw_to_processed`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)).

**Selective enrichment:** Set `outlines = FALSE` to skip geometry
enrichment, or `metadata = FALSE` to skip metadata enrichment.

The enriched VPC follows the STAC pointcloud extension specification
with additional custom properties for point and pulse density.

## Examples

``` r
if (FALSE) { # \dontrun{
# Use pre-computed outlines and metadata
vpc <- create_vpc_enriched(
  path = "output/pointcloud",
  outline_dir = "output/outlines",
  metadata_dir = "output/metadata",
  out_file = "collection.vpc"
)

# Compute on-the-fly (reads full point clouds)
vpc <- create_vpc_enriched(
  path = "data/file.laz",
  outline_dir = NULL,
  metadata_dir = NULL
)
} # }
# Typical workflow after raw_to_processed
folder <- system.file("extdata", package = "managelidar")
vpc_enriched <- folder |>
  raw_to_processed() |>
  create_vpc_enriched()
#> Process 5 LASfiles
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
