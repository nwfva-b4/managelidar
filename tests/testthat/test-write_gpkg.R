test_that("write_gpkg() accepts a character vector of metrics", {
  # regression guard: `if (metrics == TRUE)` used to error with "the
  # condition has length > 1" whenever metrics was the documented
  # character-vector form instead of TRUE/NULL
  out_file <- tempfile(fileext = ".gpkg")

  result <- expect_no_error(
    suppressMessages(write_gpkg(sample_las_files(), out_file = out_file, metrics = c("z_min", "z_max")))
  )

  expect_s3_class(result, "sf")
  expect_true(all(c("z_min", "z_max") %in% names(result)))
})
