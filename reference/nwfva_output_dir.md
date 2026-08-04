# Resolve the NWFVA output directory for a given output kind

NWFVA organises outputs under
`{root}/{region}/{platform}/{year}/{campaign}/{product}/...`, branching
into `daten/` for point clouds, `doku/vpc/` for VPC metadata, and
`doku/overview/` for overview images.

## Usage

``` r
nwfva_output_dir(
  root,
  region,
  platform,
  year,
  campaign,
  product,
  kind = c("pointcloud", "vpc", "overview")
)
```

## Arguments

- root:

  Character. Root output directory (e.g.
  [`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)'s
  `out_dir`).

- region, platform, year, campaign, product:

  Character. Path components.

- kind:

  One of `"pointcloud"`, `"vpc"`, `"overview"`.

## Value

Character scalar path (not yet created on disk).
