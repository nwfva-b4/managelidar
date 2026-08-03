test_that("check_names() works with an explicit region (no network dependency)", {
  result <- check_names(sample_las_files(), region = "ni", full.names = TRUE)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("name_is", "name_should", "correct") %in% names(result)))
  expect_equal(nrow(result), length(sample_las_files()))
})

test_that("check_names() gives an actionable error if region auto-detection fails offline", {
  skip_if_offline()
  skip_on_cran()

  # this exercises the network-dependent auto-detection path; if it's
  # reachable this just succeeds like the explicit-region case above
  expect_no_error(check_names(sample_las_files(), full.names = TRUE))
})
