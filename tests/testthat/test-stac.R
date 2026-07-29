test_that("stac_create_catalog()/stac_add_collection()/stac_add_items() build a working catalog", {
  root <- tempfile("stac-")
  cat_path <- stac_create_catalog(root, id = "lidar_ni", title = "Test Catalog")
  expect_true(file.exists(cat_path))

  col <- stac_add_collection(cat_path, id = "lidar_ni_2023", title = "Lidar Test")
  expect_true(file.exists(col))

  col <- suppressWarnings(stac_add_items(col, path = sample_las_files(), overwrite_items = TRUE))

  item_files <- list.files(file.path(dirname(col), "items"), pattern = "[.]json$")
  expect_length(item_files, length(sample_las_files()))

  collection_obj <- yyjsonr::read_json_file(col)
  expect_true(!is.null(collection_obj$assets$vpc))
  expect_true(!is.null(collection_obj$assets$footprints))
  expect_true(file.exists(file.path(dirname(col), "assets", "collection.vpc")))
  expect_true(file.exists(file.path(dirname(col), "assets", "footprints.gpkg")))
})

test_that("stac_add_collection() with multi-provider `providers` is idempotent", {
  # regression guard: yyjsonr reads a JSON array of uniformly-shaped
  # objects (providers, like links) back from disk as a data.frame, while
  # the freshly-built in-memory version is a plain list - these never
  # compared identical() regardless of content, so a collection with
  # `providers` set was reported "Updated" on every single call even when
  # nothing changed.
  providers <- list(
    list(name = "Org A", roles = c("host", "producer", "processor", "licensor"), url = "https://a.example/"),
    list(name = "Org B", roles = c("host", "processor"), url = "https://b.example/")
  )

  root <- tempfile("stac-providers-")
  cat_path <- stac_create_catalog(root, id = "lidar_ni", title = "Test Catalog")
  col <- stac_add_collection(cat_path, id = "lidar_ni_2023", title = "Lidar Test", providers = providers)
  before_updated <- yyjsonr::read_json_file(col)$updated

  Sys.sleep(1.1) # stac_timestamp() has second granularity

  col2 <- stac_add_collection(cat_path, id = "lidar_ni_2023", title = "Lidar Test", providers = providers)
  after_updated <- yyjsonr::read_json_file(col2)$updated

  expect_equal(before_updated, after_updated)
})

test_that("stac_add_items(overwrite_items = TRUE) is a true no-op on unchanged input", {
  # regression guard: item writes used to unconditionally bump
  # properties$updated (and therefore rewrite the combined VPC/GeoPackage)
  # even when nothing actually changed - see TODO.md
  root <- tempfile("stac-idempotent-")
  cat_path <- stac_create_catalog(root, id = "lidar_ni", title = "Test Catalog")
  col <- stac_add_collection(cat_path, id = "lidar_ni_2023", title = "Lidar Test")
  col <- suppressWarnings(stac_add_items(col, path = sample_las_files(), overwrite_items = TRUE))

  item_files <- list.files(file.path(dirname(col), "items"), full.names = TRUE, pattern = "[.]json$")
  before_updated <- vapply(item_files, function(f) yyjsonr::read_json_file(f)$properties$updated, character(1))
  before_collection_updated <- yyjsonr::read_json_file(col)$updated
  before_vpc_mtime <- file.mtime(file.path(dirname(col), "assets", "collection.vpc"))
  before_gpkg_mtime <- file.mtime(file.path(dirname(col), "assets", "footprints.gpkg"))

  Sys.sleep(1.1) # stac_timestamp() has second granularity

  col2 <- suppressWarnings(stac_add_items(col, path = sample_las_files(), overwrite_items = TRUE))

  after_updated <- vapply(item_files, function(f) yyjsonr::read_json_file(f)$properties$updated, character(1))
  after_collection_updated <- yyjsonr::read_json_file(col2)$updated
  after_vpc_mtime <- file.mtime(file.path(dirname(col2), "assets", "collection.vpc"))
  after_gpkg_mtime <- file.mtime(file.path(dirname(col2), "assets", "footprints.gpkg"))

  expect_equal(before_updated, after_updated)
  expect_equal(before_collection_updated, after_collection_updated)
  expect_equal(before_vpc_mtime, after_vpc_mtime)
  expect_equal(before_gpkg_mtime, after_gpkg_mtime)
})

test_that("stac_add_items() still detects and applies real changes", {
  root <- tempfile("stac-realchange-")
  cat_path <- stac_create_catalog(root, id = "lidar_ni", title = "Test Catalog")
  col <- stac_add_collection(cat_path, id = "lidar_ni_2023", title = "Lidar Test")
  col <- suppressWarnings(stac_add_items(col, path = sample_las_files()[1:2], overwrite_items = TRUE))
  before <- yyjsonr::read_json_file(col)$updated

  Sys.sleep(1.1)
  col2 <- suppressWarnings(stac_add_items(col, path = sample_las_files()[3:5], overwrite_items = TRUE))
  after <- yyjsonr::read_json_file(col2)$updated

  expect_false(identical(before, after))
  expect_length(list.files(file.path(dirname(col2), "items"), pattern = "[.]json$"), 5)
})

test_that("build_combined_vpc() incremental path matches a full rescan", {
  items_dir <- tempfile("items-")
  dir.create(items_dir)

  make_item <- function(id, x) {
    list(
      type = "Feature", collection = "test", stac_version = "1.0.0", stac_extensions = list(),
      id = id,
      geometry = list(type = "Polygon", coordinates = list(list(c(x, 0), c(x + 1, 0), c(x + 1, 1), c(x, 1), c(x, 0)))),
      bbox = list(x, 0, x + 1, 1),
      properties = list(datetime = "2024-01-01T00:00:00Z", `proj:epsg` = 25832L),
      assets = list(data = list(href = sprintf("file:///tmp/%s.laz", id), roles = list("data"))),
      links = list(list(rel = "self", href = sprintf("./%s.json", id)))
    )
  }

  n <- 20
  for (i in seq_len(n)) {
    item <- make_item(sprintf("item_%02d", i), i)
    write_stac(item, file.path(items_dir, paste0(item$id, ".json")))
  }

  existing_vpc <- build_combined_vpc(items_dir)
  expect_length(existing_vpc$features, n)

  new_id <- "item_21"
  write_stac(make_item(new_id, 21), file.path(items_dir, paste0(new_id, ".json")))

  incremental <- build_combined_vpc(items_dir, existing_vpc = existing_vpc, changed_ids = new_id)
  full_rescan <- build_combined_vpc(items_dir)

  ids_incremental <- sort(vapply(incremental$features, function(f) f$id, character(1)))
  ids_full <- sort(vapply(full_rescan$features, function(f) f$id, character(1)))
  expect_equal(ids_incremental, ids_full)

  # self-healing: a deleted item is dropped from the incremental result too
  file.remove(file.path(items_dir, "item_01.json"))
  incremental2 <- build_combined_vpc(items_dir, existing_vpc = incremental, changed_ids = character())
  expect_length(incremental2$features, n) # n + 1 - 1
  expect_false("item_01" %in% vapply(incremental2$features, function(f) f$id, character(1)))
})

test_that("path_to_file_uri() encodes spaces and handles UNC paths", {
  expect_false(grepl(" ", path_to_file_uri("C:/some folder/file name.laz")))
  expect_equal(path_to_file_uri("\\\\server\\share\\file.laz"), "file://server/share/file.laz")
  expect_equal(path_to_file_uri("C:/Users/x/file.laz"), "file:///C:/Users/x/file.laz")
})

test_that("read_stac() rejects a file with no recognizable STAC type", {
  bad_file <- tempfile(fileext = ".json")
  yyjsonr::write_json_file(list(foo = "bar"), bad_file)
  expect_error(read_stac(bad_file), class = "rlang_error")
})

test_that("stac_browse_handle_request() 404s cleanly for a missing file", {
  root <- tempfile("stac-browse-")
  cat_path <- stac_create_catalog(root, id = "lidar_ni", title = "Test Catalog")

  resp_missing <- stac_browse_handle_request(
    list(REQUEST_METHOD = "GET", PATH_INFO = "/does/not/exist.json"),
    root_dir = dirname(cat_path)
  )
  expect_equal(resp_missing$status, 404L)

  resp_ok <- stac_browse_handle_request(
    list(REQUEST_METHOD = "GET", PATH_INFO = "/catalog.json"),
    root_dir = dirname(cat_path)
  )
  expect_equal(resp_ok$status, 200L)
})
