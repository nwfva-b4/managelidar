# Resolve an image source (local path or URL) into an href usable in a STAC link or asset, optionally copying it into the catalog tree first

Local files default to being copied into `{containing_dir}/assets/`,
since a bare local path (or even a `file://` URI) can't be loaded by a
browser viewing the catalog through
[`stac_browse()`](https://wiesehahn.github.io/managelidar/reference/stac_browse.md).
URLs default to being referenced in place, since they're already
web-accessible; pass `copy = TRUE` to download and vendor them into the
catalog instead (so the catalog keeps working even if the original URL
later goes away).

## Usage

``` r
resolve_image_asset(source, containing_dir, key, copy = NULL)
```

## Arguments

- source:

  A URL (`http://`/`https://`), or a path to a local image file

- containing_dir:

  Directory of the catalog/collection file this image is being attached
  to; hrefs are made relative to this

- key:

  Base filename (without extension) to use if the image is
  copied/downloaded

- copy:

  Logical, or `NULL` to use the default described above

## Value

List with `href` (character) and `type` (character or `NULL`)
