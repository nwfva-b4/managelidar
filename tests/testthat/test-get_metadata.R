test_that("get_crs() returns a data.frame with a CRS per file", {
  result <- get_crs(sample_las_files())
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true("filename" %in% names(result))
})

test_that("get_lasversion() returns a data.frame with a version per file", {
  result <- get_lasversion(sample_las_files())
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true(all(grepl("^[0-9]+\\.[0-9]+$", result$lasversion)))
})

test_that("get_header() returns one LASheader per file", {
  result <- get_header(sample_las_files())
  expect_type(result, "list")
  expect_length(result, length(sample_las_files()))
})

test_that("get_extrabytes_attributes() returns a data.frame with a list-column", {
  result <- get_extrabytes_attributes(sample_las_files())
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true("extrabytes_attributes" %in% names(result))
})

test_that("get_spatial_extent() returns per-file and combined extents", {
  per_file <- get_spatial_extent(sample_las_files(), per_file = TRUE, verbose = FALSE)
  expect_s3_class(per_file, "data.frame")
  expect_equal(nrow(per_file), length(sample_las_files()))

  combined <- get_spatial_extent(sample_las_files(), per_file = FALSE, verbose = FALSE)
  expect_s3_class(combined, "data.frame")
  expect_equal(nrow(combined), 1)
})

test_that("get_temporal_extent() returns per-file and combined date ranges", {
  per_file <- get_temporal_extent(sample_las_files(), per_file = TRUE, verbose = FALSE)
  expect_s3_class(per_file, "data.frame")
  expect_equal(nrow(per_file), length(sample_las_files()))
})

test_that("get_summary() returns a named list, one element per file", {
  result <- suppressMessages(get_summary(sample_las_files()))
  expect_type(result, "list")
  expect_length(result, length(sample_las_files()))
})

test_that("check_tiling() returns a data.frame flagging tile size/grid validity", {
  result <- check_tiling(sample_las_files(), tolerance = 10)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true(all(c("size_ok", "grid_ok", "valid") %in% names(result)))
})

test_that("is_classified() detects classified point clouds", {
  result <- is_classified(sample_las_files())
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true(is.logical(result$classified))
})

test_that("is_indexed() reports spatial indexing status", {
  result <- is_indexed(sample_las_files())
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(sample_las_files()))
  expect_true(all(result$indexed)) # bundled sample files ship with .lax
})

test_that("is_multitemporal() detects tiles with multiple acquisitions", {
  result <- is_multitemporal(sample_las_files(), tolerance = 10)
  expect_s3_class(result, "data.frame")
  expect_true(any(result$multitemporal)) # sample data includes one multitemporal tile
})
