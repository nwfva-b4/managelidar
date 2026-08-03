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
