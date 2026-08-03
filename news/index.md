# Changelog

## managelidar 0.1.6

### Package cleanup

- Fixed
  [`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md),
  which was non-functional end-to-end: it called a nonexistent internal
  function
  ([`read_log_entries()`](https://wiesehahn.github.io/managelidar/reference/read_log_entries.md)),
  and a duplicated block re-opened an overview file the first copy had
  just deleted.
- Fixed
  [`set_names()`](https://wiesehahn.github.io/managelidar/reference/set_names.md)
  silently passing wrong arguments to
  [`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)
  due to a positional-argument mismatch after
  [`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)’s
  signature changed.
- Fixed
  [`write_gpkg()`](https://wiesehahn.github.io/managelidar/reference/write_gpkg.md)
  erroring on its own documented `metrics =` usage (a character vector),
  and
  [`create_vpc_enriched()`](https://wiesehahn.github.io/managelidar/reference/create_vpc_enriched.md)’s
  empty-VPC guard never firing
  ([`length()`](https://rdrr.io/r/base/length.html) vs
  [`nrow()`](https://rdrr.io/r/base/nrow.html)).
- Standardized error handling package-wide on `cli`.
- Converged inconsistent return types (`get_*()`/`is_*()` functions now
  consistently return a plain `data.frame`) and other naming/consistency
  cleanups.
- Fixed several robustness gaps:
  [`check_names()`](https://wiesehahn.github.io/managelidar/reference/check_names.md)’s
  runtime boundary download now fails with an actionable message instead
  of crashing;
  [`get_penetration()`](https://wiesehahn.github.io/managelidar/reference/get_penetration.md)
  handles headers with fewer return bins gracefully.
- `DESCRIPTION` now declares all packages actually used (`cli`, `mirai`,
  `httpuv`, `rlang`, `viridis`, `methods`, `stats`, `grDevices`, etc.)
  and drops unused ones (`rlas`, `data.table`); the R version floor is
  corrected to `R >= 4.1` (required by the native pipe).
- Added an initial `tests/testthat/` suite covering the fixes above,
  plus the `get_*()`/`is_*()` metadata-query family and filtering
  functions.

### Documentation

- Fixed drift in `vignettes/raw-to-processed.Rmd` against the current
  [`raw_to_processed()`](https://wiesehahn.github.io/managelidar/reference/raw_to_processed.md)
  behavior (missing `log_dir` parameter, incorrect output directory
  structure, missing `skipped_locked` status value).
- Filled in the README’s empty License section.
