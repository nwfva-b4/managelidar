# Convert VPC features to STAC items

Convert VPC features to STAC items

## Usage

``` r
vpc_to_stac_items(
  vpc_obj,
  collection_dir,
  items_dir,
  root_path,
  collection_id,
  root_title,
  collection_title
)
```

## Arguments

- vpc_obj:

  VPC object (list with \$features)

- collection_dir:

  Path to collection directory

- items_dir:

  Path to items directory

- root_path:

  Absolute path to root catalog

- collection_id:

  Parent collection ID

- root_title:

  Title of the root catalog

- collection_title:

  Title of the owning collection

## Value

List of STAC item objects
