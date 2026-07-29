test_that("filter_attribute() filters VPC features by property expressions", {
  result <- suppressMessages(filter_attribute(sample_data_dir(), `pc:count` > 5000))
  expect_type(result, "list")
  expect_true(nrow(result$features) >= 1)
  expect_true(nrow(result$features) <= length(sample_las_files()))
})

test_that("filter_earliest()/filter_latest() keep one acquisition per tile", {
  earliest <- suppressMessages(filter_earliest(sample_data_dir(), tolerance = 10))
  latest <- suppressMessages(filter_latest(sample_data_dir(), tolerance = 10))

  expect_type(earliest, "list")
  expect_type(latest, "list")
  expect_equal(nrow(earliest$features), nrow(latest$features))
})

test_that("filter_multitemporal() filters tiles by number of observations", {
  result <- suppressMessages(filter_multitemporal(sample_data_dir(), tolerance = 10))
  expect_type(result, "list")
  expect_true(nrow(result$features) >= 1)
})

test_that("get_intersection() finds files whose extents intersect", {
  result <- get_intersection(sample_las_files()[1], sample_las_files())
  expect_type(result, "list")
  expect_true(all(c("path1", "path2") %in% names(result)))
  expect_s3_class(result$path1, "data.frame")
  expect_s3_class(result$path2, "data.frame")
  # path1 is a single file so it must at least intersect itself
  expect_true(nrow(result$path1) >= 1)
  expect_true(nrow(result$path2) >= 1)
})

test_that("merge_vpcs() merges and deduplicates VPC files", {
  vpc_file1 <- tempfile(fileext = ".vpc")
  vpc_file2 <- tempfile(fileext = ".vpc")
  invisible(lasR::exec(lasR::write_vpc(vpc_file1, absolute_path = TRUE), on = sample_las_files()[1:2]))
  invisible(lasR::exec(lasR::write_vpc(vpc_file2, absolute_path = TRUE), on = sample_las_files()[3:5]))

  merged <- suppressMessages(merge_vpcs(c(vpc_file1, vpc_file2)))
  expect_type(merged, "list")
  expect_equal(nrow(merged$features), length(sample_las_files()))
})
