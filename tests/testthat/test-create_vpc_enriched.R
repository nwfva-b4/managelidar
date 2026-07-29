test_that("create_vpc_enriched() detects an empty VPC via nrow(), not length()", {
  # regression guard: `length(vpc$features) == 0` checked column count (a
  # data.frame always has several columns) instead of row count, so this
  # guard never fired for a genuinely empty VPC. Passed as an in-memory VPC
  # object (not round-tripped through JSON): yyjsonr::write_json_file()
  # segfaults on a zero-row data.frame, an unrelated upstream issue.
  empty_vpc <- list(
    type = "FeatureCollection",
    features = data.frame(id = character(0), stringsAsFactors = FALSE)
  )

  expect_warning(
    result <- create_vpc_enriched(empty_vpc),
    "No valid VPC features found"
  )
  expect_null(result)
})
