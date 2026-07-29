test_that("print_pulseinfo() prints density/penetration stats and returns NULL invisibly", {
  output <- capture.output(result <- print_pulseinfo(sample_las_files()))
  expect_null(result)
  expect_true(any(grepl("Pulse Density", output)))
  expect_true(any(grepl("Pulse Penetration Rate", output)))
})

test_that("plot_extent() returns a mapview map for per-file and combined extent", {
  m1 <- suppressMessages(plot_extent(sample_las_files(), verbose = FALSE))
  expect_s4_class(m1, "mapview")

  m2 <- suppressMessages(plot_extent(sample_las_files(), per_file = FALSE, verbose = FALSE))
  expect_s4_class(m2, "mapview")
})

test_that("run_pipeline() executes a lasR pipeline against resolved input", {
  result <- suppressMessages(run_pipeline(sample_las_files()[1], lasR::summarise()))
  expect_type(result, "list")
  expect_true(!is.null(result$npoints))
})
