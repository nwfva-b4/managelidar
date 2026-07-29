test_that("get_penetration() returns NA for return-count bins missing from the header", {
  # regression guard: indexing `Number of points by return`[[2]] through
  # [[7]] unconditionally used to throw "subscript out of bounds" for
  # headers reporting fewer than 6 return bins
  fake_header <- list(`Number of points by return` = c(100, 40, 10))

  local_mocked_bindings(
    get_header = function(path, full.names = FALSE) {
      list(fake_file.laz = fake_header)
    }
  )

  result <- get_penetration("irrelevant")

  expect_s3_class(result, "data.frame")
  expect_equal(result$single, round((100 - 40) / 100, 3))
  expect_equal(result$two, round((40 - 10) / 100, 3))
  expect_true(is.na(result$three))
  expect_true(is.na(result$four))
  expect_true(is.na(result$five))
  expect_true(is.na(result$six))
})
