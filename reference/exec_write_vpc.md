# Write a temporary VPC from LAS files, setting CRS if missing

Internal wrapper around `lasR::write_vpc` that checks whether the first
file has a valid CRS and prepends `lasR::set_crs` to the pipeline if
not.

## Usage

``` r
exec_write_vpc(
  las_files,
  epsg = 25832L,
  use_gpstime = TRUE,
  absolute_path = TRUE
)
```

## Arguments

- las_files:

  Character vector of LAS/LAZ/COPC file paths.

- epsg:

  Integer. Fallback EPSG code when CRS is missing. Default is 25832.

- use_gpstime:

  Logical. Passed to `lasR::write_vpc`. Default is TRUE.

## Value

Path to the temporary VPC file.
