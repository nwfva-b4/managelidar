# Convert a local file path to a `file://` URI

Percent-encodes the path (spaces in particular - common in lidar file
trees on Windows) so the result is a valid URI, and handles UNC paths
(`\\\\server\\share\\...`) as `file://server/share/...` rather than the
malformed `file:////server/...` a naive `"file://" + path` would
produce.

## Usage

``` r
path_to_file_uri(path)
```

## Arguments

- path:

  A local file path (Windows or POSIX style)

## Value

Character, a `file://` URI (or the path unchanged, if it's already
relative rather than absolute)
