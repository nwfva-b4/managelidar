# managelidar 0.1.8

## NWFVA naming convention

* Added support for the NWFVA filename/path convention
  (`{region}_{platform}_{year}_{campaign}_{product}_{x}_{y}.laz`, nested
  under a `region/platform/year/campaign/product/{daten,doku/vpc,doku/overview}`
  directory tree) alongside the existing AdV convention:
  * `check_names()`/`set_names()` gain a `standard = c("adv", "nwfva")`
    parameter (default `"adv"`, unchanged behavior for existing callers).
  * `raw_to_processed()` gains the same `standard` parameter plus
    `campaign`/`platform`/`product`, and a new companion function,
    `process_nwfva()`, wraps it with a simpler NWFVA-only call signature.
* Fixed a bug where `raw_to_processed()`'s own `region` parameter was never
  forwarded to filename generation (hardcoded to `NULL`), so a user-supplied
  `region` silently had no effect on output filenames.
* The AdV-specific year-correction step (rewriting the filename's year token
  after computing it from median GPS time) previously used a regex assuming
  the year was the filename's trailing token; it's now a re-call of the same
  filename builder used for initial name generation, which works for either
  naming standard.

## raw_to_processed()

* Added `reclassify`/`classify_noise`/`classify_ground`/`normalize_intensity`
  parameters (all default `TRUE`, i.e. unchanged behavior) so each of these
  density-dependent pipeline stages can be individually disabled. Mainly
  useful for testing against sparse or very small point clouds, where noise
  and ground classification can otherwise classify most or all points as
  noise, breaking overview generation (which excludes noise points).

# managelidar 0.1.7

## STAC subsystem

* Fixed a real idempotency bug: re-running `stac_add_items(overwrite_items
  = TRUE)` on unchanged input used to still bump every item's `updated`
  timestamp, cascading into a full rebuild of the collection's combined
  VPC and footprints GeoPackage assets even though nothing had changed.
  Item writes now use the same "only write if content actually changed"
  guard already used for catalogs, collections, links, and assets.
* Fixed a related idempotency gap: a collection's `providers` field (or
  any other JSON array of uniformly-shaped objects) was never compared
  correctly, since it round-trips through disk as a `data.frame` while
  the freshly-built version is a plain list - `stac_add_collection()`
  with `providers` set reported "Updated" on every call regardless of
  whether anything changed.
* The combined VPC/GeoPackage assets are now rebuilt incrementally: only
  items that actually changed are re-read and re-parsed, instead of every
  item in the collection on every call. This keeps ingesting large
  collections (thousands of items) in batches from costing O(n^2) total
  parsing work.
* Fixed several redundant file reads in the STAC collection/catalog
  bookkeeping, a `stac_browse()` request for a missing file throwing
  instead of returning a clean 404, `read_stac()` not validating that a
  file is a recognizable STAC/VPC object, and `path_to_file_uri()` not
  percent-encoding spaces or handling UNC paths correctly.
* Expanded test coverage across the STAC subsystem.

# managelidar 0.1.6

## Package cleanup

* Fixed `raw_to_processed()`, which was non-functional end-to-end: it called
  a nonexistent internal function (`read_log_entries()`), and a duplicated
  block re-opened an overview file the first copy had just deleted.
* Fixed `set_names()` silently passing wrong arguments to `check_names()`
  due to a positional-argument mismatch after `check_names()`'s signature
  changed.
* Fixed `write_gpkg()` erroring on its own documented `metrics =` usage
  (a character vector), and `create_vpc_enriched()`'s empty-VPC guard never
  firing (`length()` vs `nrow()`).
* Standardized error handling package-wide on `cli`.
* Converged inconsistent return types (`get_*()`/`is_*()` functions now
  consistently return a plain `data.frame`) and other naming/consistency
  cleanups.
* Fixed several robustness gaps: `check_names()`'s runtime boundary
  download now fails with an actionable message instead of crashing;
  `get_penetration()` handles headers with fewer return bins gracefully.
* `DESCRIPTION` now declares all packages actually used (`cli`, `mirai`,
  `httpuv`, `rlang`, `viridis`, `methods`, `stats`, `grDevices`, etc.) and
  drops unused ones (`rlas`, `data.table`); the R version floor is
  corrected to `R >= 4.1` (required by the native pipe).
* Added an initial `tests/testthat/` suite covering the fixes above, plus
  the `get_*()`/`is_*()` metadata-query family and filtering functions.

## Documentation

* Fixed drift in `vignettes/raw-to-processed.Rmd` against the current
  `raw_to_processed()` behavior (missing `log_dir` parameter, incorrect
  output directory structure, missing `skipped_locked` status value).
* Filled in the README's empty License section.
