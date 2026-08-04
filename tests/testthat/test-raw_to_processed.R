test_that("raw_to_processed() runs without the historical function/contract bugs", {
  out_dir <- tempfile("raw_to_processed_")
  dir.create(out_dir)

  # regression guard: read_log_entries() / processed_inputs_from_logs() must
  # exist and be callable with a directory (this used to error immediately
  # with "could not find function read_log_entries")
  expect_no_error(
    suppressMessages(suppressWarnings(
      raw_to_processed(sample_las_files(), out_dir = out_dir, log_dir = out_dir, verbose = FALSE, workers = 1)
    ))
  )

  log_files <- list.files(file.path(out_dir, "logfiles"), pattern = "^processing_log.*json$", full.names = TRUE)
  expect_length(log_files, 1)

  log <- yyjsonr::read_json_file(log_files[1])
  expect_equal(log$summary$files_total, length(sample_las_files()))

  # regression guard: the duplicated "convert overview" block used to reopen
  # a file it had just deleted - every file's error (if any; the bundled
  # sample data is too sparse to survive classification and may legitimately
  # fail with a GDAL/data-density error, see plan notes) must NOT be caused by
  # the fixed bugs
  errors <- log$files$error
  errors <- errors[!vapply(errors, is.null, logical(1))]
  for (err in errors) {
    expect_false(grepl("could not find function", err, fixed = TRUE))
    expect_false(grepl("EBUSY", err, fixed = TRUE))
  }

  # regression guard: at least one overview artifact makes it through (not
  # silently zero, which is what the duplicated-block bug produced for
  # every file), and never more than one per input (no duplication). Not
  # an exact-count check: the bundled sample data is right at the edge of
  # viability for the classification pipeline, so how many of the 5 files
  # produce a usable CHM can vary by run - that's the known, accepted
  # sample-data limitation, not a code regression.
  overview_files <- list.files(file.path(out_dir, "overviews"))
  expect_true(length(overview_files) >= 1)
  expect_true(length(overview_files) <= length(sample_las_files()))
})

test_that("raw_to_processed() succeeds deterministically with density-dependent stages disabled", {
  # the bundled sample data is too sparse/small to reliably survive noise and
  # ground classification (both density-dependent - see the first test in
  # this file), which is why that test can only assert ">= 1" overview
  # rather than an exact count. Disabling those stages here removes that
  # flakiness entirely, letting the rest of the pipeline (naming, VPC,
  # overview generation, logging) be verified with an exact, reliable count.
  out_dir <- tempfile("raw_to_processed_notoggle_")
  dir.create(out_dir)

  results <- suppressMessages(suppressWarnings(
    raw_to_processed(
      sample_las_files(), out_dir = out_dir, log_dir = out_dir, region = "ni",
      classify_noise = FALSE, classify_ground = FALSE,
      verbose = FALSE, workers = 1
    )
  ))

  expect_equal(sum(!vapply(results, is.null, logical(1))), length(sample_las_files()))

  pointcloud_files <- list.files(file.path(out_dir, "pointcloud"))
  overview_files <- list.files(file.path(out_dir, "overviews"))
  vpc_files <- list.files(file.path(out_dir, "metadata"))
  expect_equal(length(pointcloud_files), length(sample_las_files()))
  expect_equal(length(overview_files), length(sample_las_files()))
  expect_equal(length(vpc_files), length(sample_las_files()))
})

test_that("read_log_entries()/processed_inputs_from_logs() correctly identify already-processed inputs", {
  log_dir <- tempfile("logs_")
  dir.create(log_dir)

  input_path <- normalizePath(sample_las_files()[1], winslash = "/", mustWork = FALSE)
  output_path <- file.path(log_dir, "output.laz")

  log_data <- list(
    files = list(
      list(input = input_path, output = output_path, status = "success", size_in = 100L, size_out = 90L),
      list(input = "some/other/failed_file.laz", output = NA_character_, status = "failed", size_in = 50L, size_out = NA_integer_)
    )
  )
  yyjsonr::write_json_file(log_data, file.path(log_dir, "processing_log_test.json"), auto_unbox = TRUE)

  entries <- read_log_entries(log_dir)
  expect_s3_class(entries, "data.frame")
  expect_equal(nrow(entries), 2)
  expect_true(all(c("input", "output", "status", "size_in", "size_out") %in% names(entries)))

  processed <- processed_inputs_from_logs(log_dir)
  expect_equal(processed, input_path)
})
