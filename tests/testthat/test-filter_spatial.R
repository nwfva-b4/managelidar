test_that("filter_spatial() gives a clear error for an unresolvable CRS instead of a raw type error", {
  # regression guard: `if (sf::st_crs(extent_sf)$epsg != target_epsg)` used to
  # throw an unrelated "missing value where TRUE/FALSE needed" error when the
  # extent's CRS had no resolvable EPSG code
  extent_no_crs <- sf::st_sfc(sf::st_point(c(548700, 5725010)))

  expect_error(
    suppressMessages(filter_spatial(sample_las_files(), extent_no_crs)),
    regexp = "EPSG code"
  )
})
