# Add VPC items to STAC catalog or collection

Add items from a Virtual Point Cloud (VPC) to a STAC catalog structure
by creating a new collection or updating an existing one. Collections
can be added directly to catalogs or nested under other collections.

## Usage

``` r
stac_add(
  vpc,
  parent = NULL,
  collection_info = NULL,
  collection_path = NULL,
  overwrite_items = FALSE
)
```

## Arguments

- vpc:

  Path to VPC file or VPC object (list with type="FeatureCollection")

- parent:

  Path to parent STAC JSON file (catalog.json or collection.json).
  Required when creating a new collection with `collection_info`.
  Optional when adding to an existing collection with `collection_path`
  (parent info is read from the existing collection).

- collection_info:

  List with collection metadata for creating a new collection. Must
  include `id` field. Optional fields include: `title`, `description`,
  `license`, `keywords`, `providers`, `summaries`, `assets`,
  `stac_extensions`.

- collection_path:

  Path to existing collection.json for adding items to an existing
  collection.

- overwrite_items:

  Logical. If `TRUE`, overwrite existing item files. Default is `FALSE`
  (skip existing items).

## Value

Path to the collection file (invisibly)

## Details

Exactly one of `collection_info` or `collection_path` must be provided.

When creating a new collection (`collection_info`), the function:

- Extracts spatial and temporal extent from VPC items

- Extracts CRS information

- Creates collection structure with proper links

- Writes items to the items/ subdirectory

- Updates parent with a child link

When updating an existing collection (`collection_path`), the function:

- Merges new spatial/temporal extents with existing

- Writes new items (skipping existing unless overwrite_items=TRUE)

- Updates collection metadata

Directory structure created:

- For catalog parent: `{parent_dir}/collections/{collection_id}/`

- For collection parent: `{parent_dir}/{collection_id}/` (subcollection)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create new collection in catalog
coll_info <- list(
  id = "lidar_ni_2023",
  title = "Lidar Daten Solling 2023",
  description = "ALS data collection in Solling 2023",
  license = "other",
  keywords = c("ALS", "Lidar", "Niedersachsen"),
  summaries = list(
    platform = "Airplane",
    `pc:density` = 25
  )
)

stac_add(
  vpc = "path/to/data.vpc",
  parent = "path/to/catalog.json",
  collection_info = coll_info
)

# Add items to existing collection (parent not needed)
stac_add(
  vpc = "path/to/new_data.vpc",
  collection_path = "path/to/catalog/collections/lidar_ni_2023/collection.json"
)

# Create subcollection
subcoll_info <- list(
  id = "2023_q3",
  title = "Q3 2023 Data",
  description = "Data collected in Q3 2023",
  license = "other"
)

stac_add(
  vpc = "path/to/q3_data.vpc",
  parent = "path/to/catalog/collections/lidar_ni_2023/collection.json",
  collection_info = subcoll_info
)
} # }
```
