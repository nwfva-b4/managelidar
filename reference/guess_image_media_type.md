# Guess the media type of an image from its file extension

Strips any URL query string/fragment before checking the extension, so
this works for both local paths and URLs.

## Usage

``` r
guess_image_media_type(path)
```

## Arguments

- path:

  Path or URL to an image file

## Value

Character media type, or `NULL` (with a warning) if the extension isn't
recognized
