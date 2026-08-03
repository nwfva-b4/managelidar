# Write a STAC object only if it actually changed, resolving `created`/`updated`

Centralizes the "build/update the object, compare against the existing
on-disk version (ignoring `created`/`updated` themselves and `fs_path`
representation), only stamp `updated` and write if content really
changed" pattern used for catalogs, collections, links, assets, and
items throughout this package. Without this, re-running with identical
input would otherwise bump `updated` (and rewrite the file) every time,
since a fresh timestamp is trivially "different" from whatever was there
before - the actual cause of the idempotency bug reported in `TODO.md`
for item writes.

## Usage

``` r
write_stac_if_changed(
  existing,
  fresh,
  path,
  get_ts = function(o) list(created = o$created, updated = o$updated),
  set_ts = function(o, created, updated) {
o$created <- created
     o$updated <-
    updated
     o
 }
)
```

## Arguments

- existing:

  The object as read from disk, or `NULL` if this is new.

- fresh:

  The freshly built/updated object. Its `created`/`updated` (wherever
  `get_ts`/`set_ts` say they live) are ignored for the comparison and
  always overwritten by the result of this function.

- path:

  Path to write `fresh` to if it changed.

- get_ts:

  Function `function(obj) -> list(created=, updated=)`. Defaults to
  top-level fields (catalogs/collections); pass a custom accessor for
  objects that nest them elsewhere (e.g. STAC items, under
  `$properties`).

- set_ts:

  Function `function(obj, created, updated) -> obj`, the corresponding
  setter for `get_ts`.

## Value

List with `object` (created/updated resolved either way) and `changed`
(logical: whether it actually differs from `existing`).
