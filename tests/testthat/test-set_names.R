test_that("set_names() dry run agrees with check_names() and does not error", {
  # regression guard: set_names() used to call check_names() with positional
  # arguments that no longer matched its signature, silently passing wrong
  # values (e.g. a from_csv path into the region slot) instead of erroring
  result <- expect_no_error(
    suppressMessages(set_names(sample_las_files(), region = "ni", dry_run = TRUE, verbose = TRUE))
  )

  expect_s3_class(result, "data.frame")
  expect_true(all(c("from", "to") %in% names(result)))

  expected <- check_names(sample_las_files(), region = "ni", full.names = TRUE)
  expected <- expected[!expected$correct, ]

  expect_setequal(basename(result$to), basename(expected$name_should))
})

test_that("set_names() dry run works with the NWFVA standard", {
  result <- expect_no_error(
    suppressMessages(set_names(
      sample_las_files(),
      standard = "nwfva", region = "ni", campaign = "solling_sgb4",
      dry_run = TRUE, verbose = TRUE
    ))
  )

  expect_s3_class(result, "data.frame")
  expect_true(all(c("from", "to") %in% names(result)))

  expected <- check_names(sample_las_files(), standard = "nwfva", region = "ni", campaign = "solling_sgb4", full.names = TRUE)
  expected <- expected[!expected$correct, ]

  expect_setequal(basename(result$to), basename(expected$name_should))
})
