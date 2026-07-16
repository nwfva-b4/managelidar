# Check whether a collection's extent is still the empty placeholder written by stac_add_collection() (as opposed to a real extent derived from items). Only the spatial bbox is checked, since a zero bbox is the only placeholder signal available (STAC does not allow `null` bbox values, unlike temporal intervals).

Check whether a collection's extent is still the empty placeholder
written by stac_add_collection() (as opposed to a real extent derived
from items). Only the spatial bbox is checked, since a zero bbox is the
only placeholder signal available (STAC does not allow `null` bbox
values, unlike temporal intervals).

## Usage

``` r
extent_is_placeholder(extent)
```

## Arguments

- extent:

  Extent list as read from disk (bbox as matrix)

## Value

Logical
