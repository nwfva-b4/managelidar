# Filter VPC features by attribute values

Filters VPC features based on property values using dplyr-style
expressions.

## Usage

``` r
filter_attribute(path, ..., verbose = TRUE)
```

## Arguments

- path:

  Character vector of input paths, a VPC file path, or a VPC object
  already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc`
  files.

- ...:

  Logical expressions using property names. Multiple conditions are
  combined with AND. Use backticks for properties with special
  characters (e.g., `` `pc:count` > 10000 ``).

- verbose:

  Logical. If TRUE (default), prints information about filtering
  results.

## Value

A VPC object (list) containing only features matching the criteria.
Returns NULL invisibly if no features match the filter.

## Details

This function filters VPC features based on their properties using
familiar dplyr-style syntax. You can use standard comparison operators
and combine multiple conditions.

**Available properties in standard VPCs:**

Standard VPC files (as created by lasR) contain these properties:

- `id` - Feature identifier (exposed for convenience, not in properties)

- `datetime` - Acquisition date/time (ISO 8601 format)

- `` `pc:count` `` - Total point count

- `` `pc:type` `` - Point cloud type (typically "lidar")

- `` `proj:bbox` `` - Projected bounding box (xmin, ymin, xmax, ymax)

- `` `proj:epsg` `` - EPSG code of the CRS

- `` `proj:wkt2` `` - WKT2 CRS definition

Enriched VPCs (created with
[`create_vpc_enriched`](https://wiesehahn.github.io/managelidar/reference/create_vpc_enriched.md))
also contain:

- `pointdensity` - Points per square meter

- `pulsedensity` - Pulses per square meter

- `` `pc:statistics` `` - Statistical summaries (nested structure)

**Note:** For spatial and temporal filtering, use the dedicated
functions
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md)
and
[`filter_temporal`](https://wiesehahn.github.io/managelidar/reference/filter_temporal.md)
which handle coordinate transformations and date parsing automatically.

**Supported operators:**

- Comparison: `>`, `>=`, `<`, `<=`, `==`, `!=`

- Set membership: `%in%`

- Logical: `&` (and), `|` (or), `!` (not)

**Using property names:**

- Properties without special characters can be used directly:
  `datetime`, `id`

- Properties with `:` or `-` require backticks: `` `pc:count` ``,
  `` `proj:epsg` ``

- String values need quotes: `` `pc:type` == "lidar" ``

Features missing the specified properties are excluded from results.

## See also

[`filter_temporal`](https://wiesehahn.github.io/managelidar/reference/filter_temporal.md),
[`filter_spatial`](https://wiesehahn.github.io/managelidar/reference/filter_spatial.md),
[`filter_multitemporal`](https://wiesehahn.github.io/managelidar/reference/filter_multitemporal.md)

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")

# Filter by point count (use backticks for properties with special chars)
folder |>
  filter_attribute(`pc:count` > 5000)
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by type
folder |>
  filter_attribute(`pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Multiple conditions (AND)
folder |>
  filter_attribute(`pc:count` > 5000, `pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Using OR
folder |>
  filter_attribute(`pc:count` > 10000 | `pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by feature ID (exposed for convenience)
folder |>
  filter_attribute(id == "3dm_32_547_5724_1_ni_20240327")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter by multiple IDs
folder |>
  filter_attribute(id %in% c(
    "3dm_32_547_5724_1_ni_20240327",
    "3dm_32_548_5724_1_ni_20240327"
  ))
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Filter enriched VPC by density
folder |>
  create_vpc_enriched() |>
  filter_attribute(pointdensity >= 10)
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Chain with dedicated filter functions
folder |>
  filter_temporal("2024-03") |>
  filter_attribute(`pc:count` > 5000) |>
  filter_spatial(c(547900, 5724900, 548100, 5725100))
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

# Note: For spatial/temporal filtering, prefer dedicated functions:
folder |>
  filter_temporal("2024-03-27") # Better than filter_attribute(datetime == ...)
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’

folder |>
  filter_spatial(bbox) # Better than filter_attribute with proj:bbox
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error in loadNamespace(x): there is no package called ‘lasR’
```
