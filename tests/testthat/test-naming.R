test_that("nwfva_filename() never emits scientific notation for round coordinates", {
  # regression guard: paste0()/as.character() on a round double like 600000
  # silently switches to scientific notation ("6e+05") since that's shorter
  # than "600000" and R's default scipen has no bias toward fixed notation -
  # this only surfaces for coordinates that are round to the nearest 100000,
  # which the bundled sample data's tile coordinates never happen to be
  result <- nwfva_filename(
    region = "sh", platform = "als", year = "2023", campaign = "test",
    product = "punktwolke", x = 600000, y = 5941000, ext = "laz"
  )

  expect_equal(result, "sh_als_2023_test_punktwolke_600000_5941000.laz")
  expect_false(grepl("e[+-]", result))
})

test_that("adv_filename() and nwfva_filename() are pure string assemblers", {
  expect_equal(
    adv_filename("3dm", 32, 547, 5724, 1, "ni", "2023", "laz"),
    "3dm_32_547_5724_1_ni_2023.laz"
  )
  expect_equal(
    adv_filename("3dm", 32, 547, 5724, 1, "ni", "2023", "laz", copc = TRUE),
    "3dm_32_547_5724_1_ni_2023.copc.laz"
  )
})

test_that("prune_empty_dirs() removes an empty chain up to (not including) stop_at", {
  root <- fs::dir_create(tempfile("prune_"))
  stop_at <- fs::path(root, "sh", "als")
  leaf <- fs::dir_create(fs::path(stop_at, "2023", "test_campaign", "punktwolke", "daten"))

  prune_empty_dirs(leaf, stop_at)

  expect_false(fs::dir_exists(fs::path(stop_at, "2023")))
  expect_true(fs::dir_exists(stop_at))
})

test_that("prune_empty_dirs() stops as soon as a level is non-empty", {
  root <- fs::dir_create(tempfile("prune_nonempty_"))
  stop_at <- fs::path(root, "sh", "als")
  product_dir <- fs::dir_create(fs::path(stop_at, "2023", "test_campaign", "punktwolke"))
  daten_dir <- fs::dir_create(fs::path(product_dir, "daten"))
  # a sibling "doku" subtree still has content - product/ must survive
  fs::file_create(fs::path(fs::dir_create(fs::path(product_dir, "doku", "vpc")), "keep.vpc"))

  prune_empty_dirs(daten_dir, stop_at)

  expect_false(fs::dir_exists(daten_dir))
  expect_true(fs::dir_exists(product_dir))
  expect_true(fs::file_exists(fs::path(product_dir, "doku", "vpc", "keep.vpc")))
})

test_that("prune_empty_dirs() is a no-op when a file is still present (e.g. a lock file)", {
  root <- fs::dir_create(tempfile("prune_locked_"))
  stop_at <- fs::path(root, "sh", "als")
  leaf <- fs::dir_create(fs::path(stop_at, "2023", "test_campaign", "punktwolke", "daten"))
  lock_file <- fs::file_create(fs::path(leaf, "tile.lock"))

  prune_empty_dirs(leaf, stop_at)
  expect_true(fs::dir_exists(leaf))

  # once the lock file is gone, a retry (mirroring the on.exit retry in
  # raw_to_processed()) successfully finishes the cleanup
  fs::file_delete(lock_file)
  prune_empty_dirs(leaf, stop_at)
  expect_false(fs::dir_exists(fs::path(stop_at, "2023")))
})
