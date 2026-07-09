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
#> Filter by attribute
#>   ▼ 5 LASfiles (`pc:count` > 5000)
#>   ▼ 3 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 3 Feature        1.0.0
#> 4 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 4 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 3 3dm_32_548_5724_1_ni_20240327
#> 4 3dm_32_548_5725_1_ni_20230904
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                        geometry
#> 3  9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 4 9.694165867, 9.708528158, 9.708667547, 9.69430243, 9.694165867, 51.673981168, 51.673895414, 51.682826012, 51.682911794, 51.673981168, Polygon
#> 5  9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 4 9.694166, 51.673895, 229.795000, 9.708668, 51.682912, 387.516000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 4     2023-09-05T00:00:00Z, 10000, lidar, TRUE, 548000, 5725006.594, 548993.201, 5725999.902, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 3  NULL
#> 4  NULL
#> 5  NULL
#>                                                                                        assets
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 4 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20230904.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

# Filter by type
folder |>
  filter_attribute(`pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter by attribute
#>   ▼ 5 LASfiles (`pc:type` == "lidar")
#>   ▼ 5 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 1 Feature        1.0.0
#> 2 Feature        1.0.0
#> 3 Feature        1.0.0
#> 4 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 1 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 2 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 4 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 1 3dm_32_547_5724_1_ni_20240327
#> 2 3dm_32_547_5725_1_ni_20240327
#> 3 3dm_32_548_5724_1_ni_20240327
#> 4 3dm_32_548_5725_1_ni_20230904
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                        geometry
#> 1  9.689545624, 9.694022835, 9.694160238, 9.68968214, 9.689545624, 51.664957492, 51.664931122, 51.67392138, 51.673947759, 51.664957492, Polygon
#> 2 9.689074427, 9.694137125, 9.694273423, 9.68920973, 9.689074427, 51.673951982, 51.673922173, 51.682835744, 51.682865562, 51.673951982, Polygon
#> 3  9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 4 9.694165867, 9.708528158, 9.708667547, 9.69430243, 9.694165867, 51.673981168, 51.673895414, 51.682826012, 51.682911794, 51.673981168, Polygon
#> 5  9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 1 9.689546, 51.664931, 222.866000, 9.694160, 51.673948, 316.283000
#> 2 9.689074, 51.673922, 223.448000, 9.694273, 51.682866, 316.526000
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 4 9.694166, 51.673895, 229.795000, 9.708668, 51.682912, 387.516000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 1  2024-03-27T00:00:00Z, 2936, lidar, TRUE, 547689.999, 5724000.002, 547999.674, 5724999.941, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 2  2024-03-27T00:00:00Z, 3369, lidar, TRUE, 547647.973, 5725000.014, 547998.075, 5725991.425, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 4     2023-09-05T00:00:00Z, 10000, lidar, TRUE, 548000, 5725006.594, 548993.201, 5725999.902, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 1  NULL
#> 2  NULL
#> 3  NULL
#> 4  NULL
#> 5  NULL
#>                                                                                        assets
#> 1 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz, data
#> 2 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5725_1_ni_20240327.laz, data
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 4 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20230904.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

# Multiple conditions (AND)
folder |>
  filter_attribute(`pc:count` > 5000, `pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter by attribute
#>   ▼ 5 LASfiles (`pc:count` > 5000 & `pc:type` == "lidar")
#>   ▼ 3 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 3 Feature        1.0.0
#> 4 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 4 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 3 3dm_32_548_5724_1_ni_20240327
#> 4 3dm_32_548_5725_1_ni_20230904
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                        geometry
#> 3  9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 4 9.694165867, 9.708528158, 9.708667547, 9.69430243, 9.694165867, 51.673981168, 51.673895414, 51.682826012, 51.682911794, 51.673981168, Polygon
#> 5  9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 4 9.694166, 51.673895, 229.795000, 9.708668, 51.682912, 387.516000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 4     2023-09-05T00:00:00Z, 10000, lidar, TRUE, 548000, 5725006.594, 548993.201, 5725999.902, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 3  NULL
#> 4  NULL
#> 5  NULL
#>                                                                                        assets
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 4 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20230904.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

# Using OR
folder |>
  filter_attribute(`pc:count` > 10000 | `pc:type` == "lidar")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter by attribute
#>   ▼ 5 LASfiles (`pc:count` > 10000 | `pc:type` == "lidar")
#>   ▼ 5 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 1 Feature        1.0.0
#> 2 Feature        1.0.0
#> 3 Feature        1.0.0
#> 4 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 1 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 2 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 4 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 1 3dm_32_547_5724_1_ni_20240327
#> 2 3dm_32_547_5725_1_ni_20240327
#> 3 3dm_32_548_5724_1_ni_20240327
#> 4 3dm_32_548_5725_1_ni_20230904
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                        geometry
#> 1  9.689545624, 9.694022835, 9.694160238, 9.68968214, 9.689545624, 51.664957492, 51.664931122, 51.67392138, 51.673947759, 51.664957492, Polygon
#> 2 9.689074427, 9.694137125, 9.694273423, 9.68920973, 9.689074427, 51.673951982, 51.673922173, 51.682835744, 51.682865562, 51.673951982, Polygon
#> 3  9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 4 9.694165867, 9.708528158, 9.708667547, 9.69430243, 9.694165867, 51.673981168, 51.673895414, 51.682826012, 51.682911794, 51.673981168, Polygon
#> 5  9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 1 9.689546, 51.664931, 222.866000, 9.694160, 51.673948, 316.283000
#> 2 9.689074, 51.673922, 223.448000, 9.694273, 51.682866, 316.526000
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 4 9.694166, 51.673895, 229.795000, 9.708668, 51.682912, 387.516000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 1  2024-03-27T00:00:00Z, 2936, lidar, TRUE, 547689.999, 5724000.002, 547999.674, 5724999.941, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 2  2024-03-27T00:00:00Z, 3369, lidar, TRUE, 547647.973, 5725000.014, 547998.075, 5725991.425, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 4     2023-09-05T00:00:00Z, 10000, lidar, TRUE, 548000, 5725006.594, 548993.201, 5725999.902, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 1  NULL
#> 2  NULL
#> 3  NULL
#> 4  NULL
#> 5  NULL
#>                                                                                        assets
#> 1 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz, data
#> 2 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5725_1_ni_20240327.laz, data
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 4 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20230904.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

# Filter by feature ID (exposed for convenience)
folder |>
  filter_attribute(id == "3dm_32_547_5724_1_ni_20240327")
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter by attribute
#>   ▼ 5 LASfiles (id == "3dm_32_547_5724_1_ni_20240327")
#>   ▼ 1 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 1 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 1 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 1 3dm_32_547_5724_1_ni_20240327
#>                                                                                                                                       geometry
#> 1 9.689545624, 9.694022835, 9.694160238, 9.68968214, 9.689545624, 51.664957492, 51.664931122, 51.67392138, 51.673947759, 51.664957492, Polygon
#>                                                               bbox
#> 1 9.689546, 51.664931, 222.866000, 9.694160, 51.673948, 316.283000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            properties
#> 1 2024-03-27T00:00:00Z, 2936, lidar, TRUE, 547689.999, 5724000.002, 547999.674, 5724999.941, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 1  NULL
#>                                                                                        assets
#> 1 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz, data
#> 

# Filter by multiple IDs
folder |>
  filter_attribute(id %in% c(
    "3dm_32_547_5724_1_ni_20240327",
    "3dm_32_548_5724_1_ni_20240327"
  ))
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter by attribute
#>   ▼ 5 LASfiles (id %in% ...)
#>   ▼ 2 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 1 Feature        1.0.0
#> 3 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 1 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 1 3dm_32_547_5724_1_ni_20240327
#> 3 3dm_32_548_5724_1_ni_20240327
#>                                                                                                                                       geometry
#> 1 9.689545624, 9.694022835, 9.694160238, 9.68968214, 9.689545624, 51.664957492, 51.664931122, 51.67392138, 51.673947759, 51.664957492, Polygon
#> 3 9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#>                                                               bbox
#> 1 9.689546, 51.664931, 222.866000, 9.694160, 51.673948, 316.283000
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            properties
#> 1 2024-03-27T00:00:00Z, 2936, lidar, TRUE, 547689.999, 5724000.002, 547999.674, 5724999.941, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 3    2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 1  NULL
#> 3  NULL
#>                                                                                        assets
#> 1 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz, data
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 

# Filter enriched VPC by density
folder |>
  create_vpc_enriched() |>
  filter_attribute(pointdensity >= 10)
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Create enriched VPC with 5 features
#> No outline directory found - skipping geometry enrichment
#> No metadata directory found - skipping metadata enrichment
#> Warning: Both outlines and metadata are FALSE - nothing to enrich
#> Warning: No features match filter criteria

# Chain with dedicated filter functions
folder |>
  filter_temporal("2024-03") |>
  filter_attribute(`pc:count` > 5000) |>
  filter_spatial(c(547900, 5724900, 548100, 5725100))
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter temporal extent
#>   ▼ 5 LASfiles (2023-09-05 to 2024-03-27)
#>   ▼ 4 LASfiles retained (2024-03-27)
#> Filter by attribute
#>   ▼ 4 LASfiles (`pc:count` > 5000)
#>   ▼ 2 LASfiles retained
#> Filter spatial extent
#>   ▼ 2 LASfiles
#>   ▼ 2 LASfiles retained
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 3 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 3 3dm_32_548_5724_1_ni_20240327
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                       geometry
#> 3 9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 5 9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 3  NULL
#> 5  NULL
#>                                                                                        assets
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

# Note: For spatial/temporal filtering, prefer dedicated functions:
folder |>
  filter_temporal("2024-03-27") # Better than filter_attribute(datetime == ...)
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Filter temporal extent
#>   ▼ 5 LASfiles (2023-09-05 to 2024-03-27)
#>   ▼ 4 LASfiles retained (2024-03-27)
#> $type
#> [1] "FeatureCollection"
#> 
#> $features
#>      type stac_version
#> 1 Feature        1.0.0
#> 2 Feature        1.0.0
#> 3 Feature        1.0.0
#> 5 Feature        1.0.0
#>                                                                                                                    stac_extensions
#> 1 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 2 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 3 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#> 5 https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json, https://stac-extensions.github.io/projection/v1.1.0/schema.json
#>                              id
#> 1 3dm_32_547_5724_1_ni_20240327
#> 2 3dm_32_547_5725_1_ni_20240327
#> 3 3dm_32_548_5724_1_ni_20240327
#> 5 3dm_32_548_5725_1_ni_20240327
#>                                                                                                                                        geometry
#> 1  9.689545624, 9.694022835, 9.694160238, 9.68968214, 9.689545624, 51.664957492, 51.664931122, 51.67392138, 51.673947759, 51.664957492, Polygon
#> 2 9.689074427, 9.694137125, 9.694273423, 9.68920973, 9.689074427, 51.673951982, 51.673922173, 51.682835744, 51.682865562, 51.673951982, Polygon
#> 3  9.694027577, 9.708369514, 9.708509308, 9.694164542, 9.694027577, 51.664931076, 51.664845455, 51.673806951, 51.6738926, 51.664931076, Polygon
#> 5  9.694164975, 9.708559539, 9.708698746, 9.694301355, 9.694164975, 51.67392191, 51.673835961, 51.682754557, 51.682840533, 51.67392191, Polygon
#>                                                               bbox
#> 1 9.689546, 51.664931, 222.866000, 9.694160, 51.673948, 316.283000
#> 2 9.689074, 51.673922, 223.448000, 9.694273, 51.682866, 316.526000
#> 3 9.694028, 51.664845, 224.578000, 9.708509, 51.673893, 372.281000
#> 5 9.694165, 51.673836, 232.946000, 9.708699, 51.682841, 385.486000
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             properties
#> 1  2024-03-27T00:00:00Z, 2936, lidar, TRUE, 547689.999, 5724000.002, 547999.674, 5724999.941, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 2  2024-03-27T00:00:00Z, 3369, lidar, TRUE, 547647.973, 5725000.014, 547998.075, 5725991.425, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 3     2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.002, 5724000, 548991.993, 5724996.743, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#> 5 2024-03-27T00:00:00Z, 10000, lidar, TRUE, 548000.001, 5725000.003, 548995.435, 5725991.976, PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["European Terrestrial Reference System 1989 ensemble",MEMBER["European Terrestrial Reference Frame 1989"],MEMBER["European Terrestrial Reference Frame 1990"],MEMBER["European Terrestrial Reference Frame 1991"],MEMBER["European Terrestrial Reference Frame 1992"],MEMBER["European Terrestrial Reference Frame 1993"],MEMBER["European Terrestrial Reference Frame 1994"],MEMBER["European Terrestrial Reference Frame 1996"],MEMBER["European Terrestrial Reference Frame 1997"],MEMBER["European Terrestrial Reference Frame 2000"],MEMBER["European Terrestrial Reference Frame 2005"],MEMBER["European Terrestrial Reference Frame 2014"],MEMBER["European Terrestrial Reference Frame 2020"],ELLIPSOID["GRS 1980",6378137,298.257222101,LENGTHUNIT["metre",1]],ENSEMBLEACCURACY[0.1]],PRIMEM["Greenwich",0,ANGLEUNIT["degree",0.0174532925199433]],ID["EPSG",4258]],CONVERSION["UTM zone 32N",METHOD["Transverse Mercator",ID["EPSG",9807]],PARAMETER["Latitude of natural origin",0,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8801]],PARAMETER["Longitude of natural origin",9,ANGLEUNIT["degree",0.0174532925199433],ID["EPSG",8802]],PARAMETER["Scale factor at natural origin",0.9996,SCALEUNIT["unity",1],ID["EPSG",8805]],PARAMETER["False easting",500000,LENGTHUNIT["metre",1],ID["EPSG",8806]],PARAMETER["False northing",0,LENGTHUNIT["metre",1],ID["EPSG",8807]]],CS[Cartesian,2],AXIS["(E)",east,ORDER[1],LENGTHUNIT["metre",1]],AXIS["(N)",north,ORDER[2],LENGTHUNIT["metre",1]],USAGE[SCOPE["Engineering survey, topographic mapping."],AREA["Europe between 6°E and 12°E: Austria; Denmark - onshore and offshore; Germany - onshore and offshore; Italy - onshore and offshore; Norway including Svalbard - onshore and offshore; Spain - offshore."],BBOX[36.53,6,84.01,12.01]],USAGE[SCOPE["Pan-European conformal mapping at scales larger than 1:500,000."],AREA["Europe between 6°E and 12°E and approximately 36°30'N to 84°N."],BBOX[36.53,6,84.01,12.01]],ID["EPSG",25832]], 25832
#>   links
#> 1  NULL
#> 2  NULL
#> 3  NULL
#> 5  NULL
#>                                                                                        assets
#> 1 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5724_1_ni_20240327.laz, data
#> 2 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_547_5725_1_ni_20240327.laz, data
#> 3 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5724_1_ni_20240327.laz, data
#> 5 /home/runner/work/_temp/Library/managelidar/extdata/3dm_32_548_5725_1_ni_20240327.laz, data
#> 

folder |>
  filter_spatial(bbox) # Better than filter_attribute with proj:bbox
#> Warning: This LAS object stores the CRS as WKT. CRS field might not be correctly populated, yielding uncertain results; use 'wkt()' instead.
#> Error: object 'bbox' not found
```
