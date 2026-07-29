test_that("normalize_temporal_range()/parse_datetime_input() dedup is behavior-preserving", {
  # regression guard: normalize_temporal_range() used to re-implement its own
  # copy of the date-format regex cascade instead of delegating to
  # parse_datetime_input() - verify all 6 documented input forms still agree
  files <- sample_las_files()

  n_day <- nrow(suppressMessages(filter_temporal(files, "2024-03-27"))$features)
  n_month <- nrow(suppressMessages(filter_temporal(files, "2024-03"))$features)
  n_year <- nrow(suppressMessages(filter_temporal(files, "2024"))$features)
  n_range <- nrow(suppressMessages(filter_temporal(files, "2024-03-01", "2024-03-31"))$features)
  n_datetime <- nrow(suppressMessages(filter_temporal(files, "2024-03-27T00:00:00Z", "2024-03-27T12:00:00Z"))$features)
  n_date_obj <- nrow(suppressMessages(filter_temporal(files, as.Date("2024-03-27")))$features)

  expect_equal(n_day, n_month)
  expect_equal(n_day, n_year)
  expect_equal(n_day, n_range)
  expect_equal(n_day, n_datetime)
  expect_equal(n_day, n_date_obj)
  expect_gt(n_day, 0)
})

test_that("parse_datetime_input() rejects unparseable strings with a cli error", {
  expect_error(parse_datetime_input("not-a-date"), class = "rlang_error")
})
