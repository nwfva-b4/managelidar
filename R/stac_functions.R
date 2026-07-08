# STAC Management Functions
# User-facing functions for managing STAC catalogs and collections
# Part of the managelidar package

#' Create a new STAC catalog
#'
#' Creates a new root STAC catalog at the given path. This is the entry
#' point of a STAC tree; collections are added underneath it with
#' [stac_add_collection()].
#'
#' @param path Directory in which to create the catalog. `catalog.json` is
#'   written inside this directory.
#' @param id Catalog ID.
#' @param title Catalog title. Defaults to `id`.
#' @param description Catalog description. Defaults to `"STAC catalog"`.
#'
#' @return Path to `catalog.json` (invisibly), for piping into
#'   [stac_add_collection()].
#'
#' @examples
#' tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni", title = "Sample Catalog")
#'
#' @export
stac_create_catalog <- function(path, id, title = id, description = "STAC catalog") {
  fs::dir_create(path)
  catalog_file <- fs::path(path, "catalog.json")

  if (fs::file_exists(catalog_file)) {
    cli::cli_alert_warning("Catalog already exists: {.path {catalog_file}}")
    return(invisible(catalog_file))
  }

  catalog_obj <- build_catalog(id = id, title = title, description = description)
  catalog_obj$links <- build_catalog_links(catalog_file, path)

  write_stac(catalog_obj, catalog_file)

  cli::cli_alert_success("Created catalog {.field {id}} at {.path {catalog_file}}")

  invisible(catalog_file)
}

#' Add a new (empty) collection to a STAC catalog or collection
#'
#' Creates a new collection nested under a catalog or another collection.
#' The collection starts out empty; use [stac_add_items()] to populate it
#' with items afterwards.
#'
#' @param parent Path to parent STAC JSON file (`catalog.json` or
#'   `collection.json`). Can be the output of [stac_create_catalog()] or a
#'   previous [stac_add_collection()] call (to nest a subcollection).
#' @param id Collection ID.
#' @param title Collection title. Defaults to `id`.
#' @param description Collection description. Defaults to `"STAC collection"`.
#' @param license License string. Defaults to `"other"`.
#' @param keywords Character vector of keywords.
#' @param providers List of provider objects.
#' @param summaries List of summary objects. `proj:epsg` and `pc:type` are
#'   added automatically by [stac_add_items()] once items are added.
#' @param assets List of asset objects.
#' @param stac_extensions Character vector of extension URLs.
#'
#' @details
#' Directory structure created:
#' \itemize{
#'   \item For catalog parent: `{parent_dir}/collections/{id}/`
#'   \item For collection parent: `{parent_dir}/{id}/` (subcollection)
#' }
#'
#' The new collection is written with a placeholder empty extent (zero
#' bbox, `NULL` temporal interval), which [stac_add_items()] replaces with
#' the real extent the first time items are added.
#'
#' @return Path to the new `collection.json` (invisibly), for piping into
#'   [stac_add_collection()] (subcollection) or [stac_add_items()].
#'
#' @examples
#' tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni") |>
#'   stac_add_collection(id = "lidar_ni_2023", title = "Lidar Solling 2023") |>
#'   stac_add_collection(id = "2023_q3", title = "Q3 2023 Data")
#'
#' @export
stac_add_collection <- function(
  parent,
  id,
  title = id,
  description = "STAC collection",
  license = "other",
  keywords = NULL,
  providers = NULL,
  summaries = NULL,
  assets = NULL,
  stac_extensions = NULL
) {
  if (!fs::file_exists(parent)) {
    cli::cli_abort("Parent STAC file does not exist: {.path {parent}}")
  }

  collection_dir <- resolve_collection_dir(parent, id)
  collection_file <- fs::path(collection_dir, "collection.json")

  if (fs::file_exists(collection_file)) {
    cli::cli_alert_warning("Collection already exists: {.path {collection_file}}")
    cli::cli_alert_info("Use {.fn stac_add_items} to add items to it")
    return(invisible(collection_file))
  }

  items_dir <- get_items_dir(collection_dir)

  collection_obj <- build_collection(
    id = id,
    title = title,
    description = description,
    extent = empty_extent(),
    license = license,
    stac_extensions = stac_extensions %||% required_lidar_stac_extensions(),
    keywords = keywords,
    providers = providers,
    summaries = summaries,
    assets = assets
  )

  collection_obj$links <- build_collection_links(collection_dir, parent)

  write_stac(collection_obj, collection_file)

  parent_obj <- read_stac(parent)
  child_rel_path <- fs::path(".", fs::path_rel(collection_file, fs::path_dir(parent)))
  parent_obj <- add_child_link(parent_obj, child_rel_path, child_title = title)
  write_stac(parent_obj, parent)

  cli::cli_alert_success("Created collection {.field {id}} at {.path {collection_file}}")
  cli::cli_alert_success("Updated parent {.field {parent_obj$id}} at {.path {parent}}")

  invisible(collection_file)
}

#' Propagate a new extent up the STAC tree
#'
#' Walks up the chain of `parent` links starting from `collection_path`,
#' updating each ancestor collection's extent to account for the new items
#' just added lower in the tree. Stops once it reaches a Catalog (which has
#' no `extent` field) or runs out of `parent` links.
#'
#' @param collection_path Path to the collection whose ancestors should be
#'   updated (typically the collection items were just added to).
#' @param spatial_extent Spatial extent of the newly added items
#'   (list format, as returned by [extract_spatial_extent()]).
#' @param temporal_extent Temporal extent of the newly added items
#'   (list format, as returned by [extract_temporal_extent()]).
#' @return Invisible NULL
#' @keywords internal
propagate_extent_to_ancestors <- function(collection_path, spatial_extent, temporal_extent) {
  collection_dir <- fs::path_dir(collection_path)
  obj <- read_stac(collection_path)

  parent_link <- find_link(obj$links, "parent")
  if (is.null(parent_link)) {
    return(invisible())
  }

  parent_path <- fs::path_abs(parent_link$href, start = collection_dir)
  parent_obj <- read_stac(parent_path)

  if (get_stac_type(parent_obj) != "Collection") {
    return(invisible()) # reached the root catalog; catalogs have no extent
  }

  if (extent_is_placeholder(parent_obj$extent)) {
    parent_obj$extent$spatial <- spatial_extent
    parent_obj$extent$temporal <- temporal_extent
  } else {
    parent_obj$extent$spatial <- merge_spatial_extents(parent_obj$extent$spatial, spatial_extent)
    parent_obj$extent$temporal <- merge_temporal_extents(parent_obj$extent$temporal, temporal_extent)
  }

  write_stac(parent_obj, parent_path)
  cli::cli_alert_success("Updated extent of ancestor collection {.field {parent_obj$id}} at {.path {parent_path}}")

  propagate_extent_to_ancestors(parent_path, spatial_extent, temporal_extent)
}

#' Add LASfile items to an existing STAC collection
#'
#' Converts LASfiles (via VPC) to STAC items and writes them into an
#' existing collection, updating the collection's extent and summaries.
#'
#' @param collection Path to an existing `collection.json`, typically the
#'   output of [stac_add_collection()].
#' @param path Character vector of input paths, or a list containing VPC
#'   objects. Can be a mix of file paths (strings) and VPC objects (lists
#'   with `type = "FeatureCollection"`).
#' @param overwrite_items Logical. If `TRUE`, overwrite existing item files.
#'   Default is `FALSE` (skip existing items).
#'
#' @details
#' If the collection is currently empty, its placeholder extent is
#' *replaced* with the extent computed from this batch of items. If the
#' collection already contains items, the new extent is *merged* with the
#' existing one instead.
#'
#' @return Path to `collection.json` (invisibly), for piping into further
#'   [stac_add_items()] calls.
#'
#' @examples
#' \dontrun{
#' "path/to/catalog/collections/lidar_ni_2023/collection.json" |>
#'   stac_add_items(path = "path/to/new_data.vpc")
#' }
#'
#' @export
stac_add_items <- function(collection, path, overwrite_items = FALSE) {
  if (!fs::file_exists(collection)) {
    cli::cli_abort("Collection file does not exist: {.path {collection}}")
  }

  collection_obj <- read_stac(collection)
  collection_dir <- fs::path_dir(collection)
  collection_id <- collection_obj$id
  items_dir <- get_items_dir(collection_dir)

  # Was the collection empty before this call? Determines replace vs merge.
  existing_item_count <- length(fs::dir_ls(items_dir, glob = "*.json", fail = FALSE))
  is_first_batch <- existing_item_count == 0

  # Root is already known from the collection's own links
  root_link <- find_link(collection_obj$links, "root")
  if (is.null(root_link)) {
    cli::cli_abort("Collection has no root link - malformed STAC structure")
  }
  root_path <- fs::path_abs(root_link$href, start = collection_dir)

  vpc_obj <- resolve_vpc(path)

  spatial_extent <- extract_spatial_extent(vpc_obj)
  temporal_extent <- extract_temporal_extent(vpc_obj)
  crs <- extract_crs(vpc_obj)

  items <- vpc_to_stac_items(vpc_obj, collection_dir, items_dir, root_path, collection_id)

  written_ids <- write_items(items, items_dir, overwrite = overwrite_items)
  skipped_count <- length(items) - length(written_ids)

  if (skipped_count > 0) {
    cli::cli_alert_warning(
      "Skipped {skipped_count} existing item{?s} (use {.code overwrite_items = TRUE} to replace)"
    )
  }

  if (length(written_ids) == 0 && skipped_count == 0) {
    cli::cli_alert_warning("No items to write")
  }

  # Update extent: replace if this is the first batch, merge otherwise
  if (is_first_batch) {
    collection_obj$extent$spatial <- spatial_extent
    collection_obj$extent$temporal <- temporal_extent
  } else {
    collection_obj$extent$spatial <- merge_spatial_extents(
      collection_obj$extent$spatial,
      spatial_extent
    )
    collection_obj$extent$temporal <- merge_temporal_extents(
      collection_obj$extent$temporal,
      temporal_extent
    )
  }

  # Ensure CRS / point cloud type summaries are present
  summaries <- collection_obj$summaries
  if (is.null(summaries)) summaries <- list()
  summaries$`proj:epsg` <- list(crs)
  summaries$`pc:type` <- list("lidar")
  collection_obj$summaries <- summaries

  # These summary fields belong to the pointcloud/projection extensions;
  # make sure both are declared on the collection
  collection_obj$stac_extensions <- union(
    collection_obj$stac_extensions,
    required_lidar_stac_extensions()
  )

  # Keep the collection's per-item `item` links in sync with items on disk
  collection_obj$links <- rebuild_item_links(collection_obj$links, collection_dir, items_dir)

  write_stac(collection_obj, collection)

  if (length(written_ids) > 0) {
    cli::cli_alert_success("Created {length(written_ids)} item{?s} in {.path {items_dir}}")
  }
  cli::cli_alert_success("Updated collection {.field {collection_obj$id}} at {.path {collection}}")

  propagate_extent_to_ancestors(collection, spatial_extent, temporal_extent)

  invisible(collection)
}
