# Build a collection object structure

Build a collection object structure

## Usage

``` r
build_collection(
  id,
  title,
  description,
  extent,
  license,
  stac_extensions = required_lidar_stac_extensions(),
  keywords = NULL,
  providers = NULL,
  summaries = NULL,
  assets = NULL,
  ...
)
```

## Arguments

- id:

  Collection ID

- title:

  Collection title

- description:

  Collection description

- extent:

  Extent list with spatial and temporal

- license:

  License string

- stac_extensions:

  Character vector of extension URLs

- keywords:

  Character vector of keywords

- providers:

  List of provider objects

- summaries:

  List of summary objects

- assets:

  List of asset objects

- ...:

  Additional fields

## Value

List with collection structure (no links)
