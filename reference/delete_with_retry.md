# Delete a file, retrying briefly if it is transiently locked

On Windows, GDAL/antivirus can briefly hold a file handle open after
`$close()` returns, causing
[`fs::file_delete()`](https://fs.r-lib.org/reference/delete.html) to
fail with `[EBUSY]` even though the file is otherwise unused. Retries a
few times with a short pause before giving up.

## Usage

``` r
delete_with_retry(path, attempts = 3L, wait = 0.2)
```

## Arguments

- path:

  Character. Path to the file to delete.

- attempts:

  Integer. Number of attempts before giving up (default 3).

- wait:

  Numeric. Seconds to wait between attempts (default 0.2).

## Value

Logical, invisibly: `TRUE` if the file was deleted (or already absent),
`FALSE` if all attempts failed.
