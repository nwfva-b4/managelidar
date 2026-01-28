# Resolve LAS/LAZ/COPC input paths

Resolves a character vector of file system paths or VPC objects into a
flat character vector of LAS/LAZ/COPC file paths. Inputs may be
individual files, directories, `.vpc` files, or VPC objects already
loaded in R. Unsupported paths and formats are silently ignored.

## Usage

``` r
resolve_las_paths(paths)
```

## Arguments

- paths:

  Character vector of file or directory paths, or a list that may
  contain VPC objects (lists with `type = "FeatureCollection"`).

## Value

A character vector of resolved LAS/LAZ/COPC file paths. Returns an empty
character vector (invisibly) if no valid files are found.

## Details

This function is intended for internal use. It performs no validation
beyond basic existence checks and never errors or warns.

Supported inputs:

- Individual `.las`, `.laz`, or `.copc` files

- Directories (non-recursive search)

- `.vpc` files (assets are extracted from the VPC JSON)

- VPC objects already loaded in R (lists with
  `type = "FeatureCollection"`)

Unsupported file formats, non-existent paths, empty directories, and
unreadable `.vpc` files are silently skipped.
