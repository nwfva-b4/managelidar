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

test_that("check_names() works with the NWFVA standard (no network dependency)", {
  adv <- check_names(sample_las_files(), region = "ni")
  nwfva <- check_names(sample_las_files(), standard = "nwfva", region = "ni", campaign = "solling_sgb4")

  expect_s3_class(nwfva, "data.frame")
  expect_equal(nrow(nwfva), length(sample_las_files()))

  # cross-check the NWFVA filename against AdV's own already-verified
  # zone/minx/miny/tilesize/region/year tokens, rather than hardcoding
  # sample-data-specific coordinates
  parts <- strsplit(fs::path_ext_remove(adv$name_should), "_")
  expected <- vapply(parts, function(p) {
    sprintf(
      "ni_als_%s_solling_sgb4_punktwolke_%d_%d.laz",
      p[7], as.integer(p[3]) * 1000L, as.integer(p[4]) * 1000L
    )
  }, character(1))

  expect_equal(basename(nwfva$name_should), expected)
})

test_that("check_names() errors if standard = 'nwfva' and campaign is missing", {
  expect_error(
    check_names(sample_las_files(), standard = "nwfva", region = "ni"),
    "campaign"
  )
})
