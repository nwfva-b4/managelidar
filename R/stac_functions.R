# STAC Management Functions
# User-facing functions for managing STAC catalogs and collections
# Part of the managelidar package

#' Create (or update) a STAC catalog
#'
#' Creates a new root STAC catalog at the given path. This is the entry
#' point of a STAC tree; collections are added underneath it with
#' [stac_add_collection()].
#'
#' If a catalog already exists at `path`, it is updated in place instead
#' of being recreated: any argument you explicitly pass (`title`,
#' `description`, `icon`) is applied; anything you don't pass is left
#' untouched, so re-running this with just a new `icon` won't reset the
#' title back to its default. Existing links (e.g. `child` links to
#' collections added since) are preserved.
#'
#' @param path Directory in which to create the catalog. `catalog.json` is
#'   written inside this directory.
#' @param id Catalog ID. Ignored (with a warning) if a catalog already
#'   exists at `path` with a different ID, since IDs aren't renamed here.
#' @param title Catalog title. Defaults to `id` for a new catalog; left
#'   unchanged on update unless explicitly passed.
#' @param description Catalog description. Defaults to `"STAC catalog"`
#'   for a new catalog; left unchanged on update unless explicitly passed.
#' @param icon A URL, or a path to a local image file, to set as the
#'   catalog's icon link (shown in headers/listings by STAC Browser and
#'   similar clients). See [stac_set_icon()] for details.
#' @param copy Whether to copy `icon` into the catalog tree rather than
#'   reference it in place. See [stac_set_icon()] for the default
#'   behavior.
#'
#' @return Path to `catalog.json` (invisibly), for piping into
#'   [stac_add_collection()].
#'
#' @examples
#' tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni", title = "Sample Catalog")
#'
#' @export
stac_create_catalog <- function(path, id, title = id, description = "STAC catalog", icon = NULL, copy = NULL) {
  fs::dir_create(path)
  catalog_file <- fs::path(path, "catalog.json")
  already_exists <- fs::file_exists(catalog_file)

  if (already_exists) {
    catalog_obj <- read_stac(catalog_file)

    if (!identical(catalog_obj$id, id)) {
      cli::cli_alert_warning(
        "Existing catalog ID {.field {catalog_obj$id}} differs from {.field {id}} - keeping the existing ID"
      )
    }
    if (!missing(title)) catalog_obj$title <- title
    if (!missing(description)) catalog_obj$description <- description
  } else {
    catalog_obj <- build_catalog(id = id, title = title, description = description)
  }

  fresh_links <- build_catalog_links(catalog_file, path, catalog_obj$title)
  for (l in fresh_links) {
    catalog_obj$links <- set_link(catalog_obj$links, l)
  }

  write_stac(catalog_obj, catalog_file)

  if (already_exists) {
    cli::cli_alert_success("Updated catalog {.field {catalog_obj$id}} at {.path {catalog_file}}")
  } else {
    cli::cli_alert_success("Created catalog {.field {id}} at {.path {catalog_file}}")
  }

  if (!is.null(icon)) {
    stac_set_icon(catalog_file, icon, copy = copy)
  }

  invisible(catalog_file)
}

#' Add (or update) a collection on a STAC catalog or collection
#'
#' Creates a new collection nested under a catalog or another collection.
#' A freshly created collection starts out empty; use [stac_add_items()]
#' to populate it with items afterwards.
#'
#' If a collection with this `id` already exists under `parent`, it's
#' updated in place instead of being recreated: any argument you
#' explicitly pass (`title`, `description`, `license`, `keywords`,
#' `providers`, `summaries`, `assets`, `stac_extensions`, `thumbnail`,
#' `overview`, `icon`) is applied; anything you don't pass is left
#' untouched, so re-running this to just add a `thumbnail` won't reset
#' the title or wipe out items already added. The collection's `extent`
#' is never touched here - only [stac_add_items()] manages it.
#'
#' @param parent Path to parent STAC JSON file (`catalog.json` or
#'   `collection.json`). Can be the output of [stac_create_catalog()] or a
#'   previous [stac_add_collection()] call (to nest a subcollection).
#' @param id Collection ID.
#' @param title Collection title. Defaults to `id` for a new collection;
#'   left unchanged on update unless explicitly passed.
#' @param description Collection description. Defaults to
#'   `"STAC collection"` for a new collection; left unchanged on update
#'   unless explicitly passed.
#' @param license License string. Defaults to `"other"` for a new
#'   collection; left unchanged on update unless explicitly passed.
#' @param keywords Character vector of keywords.
#' @param providers List of provider objects.
#' @param summaries List of summary objects. `proj:epsg` and `pc:type` are
#'   added automatically by [stac_add_items()] once items are added.
#' @param assets List of asset objects. For a thumbnail/overview image,
#'   prefer the `thumbnail`/`overview` arguments below instead of building
#'   this by hand.
#' @param stac_extensions Character vector of extension URLs.
#' @param thumbnail A URL, or a path to a local image file, to set as the
#'   collection's thumbnail asset. See [stac_add_collection_asset()].
#' @param overview A URL, or a path to a local image file, to set as the
#'   collection's overview asset. See [stac_add_collection_asset()].
#' @param icon A URL, or a path to a local image file, to set as the
#'   collection's icon link (shown in headers/listings). See
#'   [stac_set_icon()].
#' @param copy Whether to copy `thumbnail`/`overview`/`icon` into the
#'   catalog tree rather than reference them in place. See
#'   [stac_add_collection_asset()]/[stac_set_icon()] for the default
#'   behavior.
#'
#' @details
#' Directory structure created:
#' \itemize{
#'   \item For catalog parent: `{parent_dir}/collections/{id}/`
#'   \item For collection parent: `{parent_dir}/{id}/` (subcollection)
#' }
#'
#' A newly created collection is written with a placeholder empty extent
#' (zero bbox, `NULL` temporal interval), which [stac_add_items()]
#' replaces with the real extent the first time items are added.
#'
#' @return Path to the collection's `collection.json` (invisibly), for
#'   piping into [stac_add_collection()] (subcollection) or
#'   [stac_add_items()].
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
  stac_extensions = NULL,
  thumbnail = NULL,
  overview = NULL,
  icon = NULL,
  copy = NULL
) {
  if (!fs::file_exists(parent)) {
    cli::cli_abort("Parent STAC file does not exist: {.path {parent}}")
  }

  collection_dir <- resolve_collection_dir(parent, id)
  collection_file <- fs::path(collection_dir, "collection.json")
  already_exists <- fs::file_exists(collection_file)
  get_items_dir(collection_dir) # ensure items/ exists either way

  if (already_exists) {
    collection_obj <- read_stac(collection_file)

    if (!missing(title)) collection_obj$title <- title
    if (!missing(description)) collection_obj$description <- description
    if (!missing(license)) collection_obj$license <- license
    if (!missing(keywords)) collection_obj$keywords <- keywords
    if (!missing(providers)) collection_obj$providers <- providers
    if (!missing(summaries)) collection_obj$summaries <- summaries
    if (!missing(assets)) collection_obj$assets <- assets
    if (!missing(stac_extensions)) collection_obj$stac_extensions <- stac_extensions
  } else {
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
  }

  fresh_links <- build_collection_links(collection_dir, parent, collection_obj$title)
  for (l in fresh_links) {
    collection_obj$links <- set_link(collection_obj$links, l)
  }

  write_stac(collection_obj, collection_file)

  parent_obj <- read_stac(parent)
  child_rel_path <- fs::path(".", fs::path_rel(collection_file, fs::path_dir(parent)))
  parent_obj <- add_child_link(parent_obj, child_rel_path, child_title = collection_obj$title)
  write_stac(parent_obj, parent)

  if (already_exists) {
    cli::cli_alert_success("Updated collection {.field {id}} at {.path {collection_file}}")
  } else {
    cli::cli_alert_success("Created collection {.field {id}} at {.path {collection_file}}")
  }
  cli::cli_alert_success("Updated parent {.field {parent_obj$id}} at {.path {parent}}")

  if (!is.null(thumbnail)) {
    stac_add_collection_asset(collection_file, thumbnail, roles = "thumbnail", copy = copy)
  }
  if (!is.null(overview)) {
    stac_add_collection_asset(collection_file, overview, roles = "overview", copy = copy)
  }
  if (!is.null(icon)) {
    stac_set_icon(collection_file, icon, copy = copy)
  }

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

#' Set an icon on a catalog or collection
#'
#' Adds a link with `rel: "icon"`. STAC Browser (and other clients) use
#' this - specifically a *link*, not an asset - to show a small icon in
#' the page header and in lists of Catalogs, Collections and Items. This
#' works on both catalogs and collections.
#'
#' For a preview image shown on a collection's own page (not in listings),
#' use [stac_add_collection_asset()] with `roles = "thumbnail"` instead -
#' that's an asset, not a link, which is a different STAC Browser
#' convention for a different purpose.
#'
#' @param stac_object Path to a `catalog.json` or `collection.json`.
#' @param source A URL, or a path to a local image file (png, jpg/jpeg,
#'   webp, gif, or tif/tiff).
#' @param copy Whether to copy the image into the catalog tree rather than
#'   reference it in place. Defaults to `FALSE` for URLs (already
#'   web-accessible) and `TRUE` for local files (otherwise unreachable from
#'   a browser via [stac_browse()]).
#'
#' @return Path to `stac_object` (invisibly), for piping into further
#'   calls.
#'
#' @examples
#' cat <- tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni")
#' col <- cat |>
#'   stac_add_collection(id = "lidar_ni", title = "Lidar Solling", keywords = c("lidar", "ALS", "Solling", "test")) |> 
#'   stac_set_icon("https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png")
#'
#' @export
stac_set_icon <- function(stac_object, source, copy = NULL) {
  if (!fs::file_exists(stac_object)) {
    cli::cli_abort("STAC file does not exist: {.path {stac_object}}")
  }

  obj_dir <- fs::path_dir(stac_object)
  resolved <- resolve_image_asset(source, obj_dir, key = "icon", copy = copy)

  obj <- read_stac(stac_object)

  icon_link <- list(rel = "icon", href = resolved$href)
  if (!is.null(resolved$type)) icon_link$type <- resolved$type
  obj$links <- set_link(obj$links, icon_link)

  write_stac(obj, stac_object)
  cli::cli_alert_success("Set icon on {.path {stac_object}}")

  invisible(stac_object)
}

#' Add a visual asset (thumbnail, overview, ...) to a collection
#'
#' Registers an image as a collection-level asset, using `roles` to tell
#' STAC Browser (and other clients) how to display it - `"thumbnail"` is
#' shown as a preview image on the collection's own page. For an icon
#' shown in headers and listings, use [stac_set_icon()] instead - STAC
#' Browser treats icons as *links*, not assets, which is a different
#' mechanism.
#'
#' @param collection Path to an existing `collection.json`.
#' @param source A URL, or a path to a local image file (png, jpg/jpeg,
#'   webp, gif, or tif/tiff).
#' @param roles Character vector of asset roles. Defaults to
#'   `"thumbnail"`. Multiple roles can be combined on the same image, e.g.
#'   `c("thumbnail", "overview")`.
#' @param key Asset key (dictionary key under `assets`). Defaults to the
#'   first role (e.g. `"thumbnail"`). A second call with the same key
#'   replaces it.
#' @param title Asset title. Defaults to a title-cased version of `key`.
#' @param copy Whether to copy the image into the catalog tree rather than
#'   reference it in place. Defaults to `FALSE` for URLs (already
#'   web-accessible) and `TRUE` for local files (otherwise unreachable from
#'   a browser via [stac_browse()]).
#'
#' @return Path to `collection.json` (invisibly), for piping into further
#'   calls.
#'
#' @examples
#' cat <- tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni") 
#' col <- cat |>
#'   stac_add_collection(id = "lidar_ni", title = "Lidar Solling", keywords = c("lidar", "ALS", "Solling", "test")) |> 
#'   stac_add_collection_asset(
#'     "https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png",
#'     roles = "thumbnail"
#'   )
#'
#' @export
stac_add_collection_asset <- function(
  collection,
  source,
  roles = "thumbnail",
  key = NULL,
  title = NULL,
  copy = NULL
) {
  if (!fs::file_exists(collection)) {
    cli::cli_abort("Collection file does not exist: {.path {collection}}")
  }

  key <- key %||% roles[1]
  collection_dir <- fs::path_dir(collection)
  resolved <- resolve_image_asset(source, collection_dir, key = key, copy = copy)

  collection_obj <- read_stac(collection)

  assets <- collection_obj$assets
  if (is.null(assets)) assets <- list()

  asset <- list(href = resolved$href)
  if (!is.null(resolved$type)) asset$type <- resolved$type
  asset$title <- title %||% tools::toTitleCase(gsub("[_-]", " ", key))
  asset$roles <- as.list(roles)

  assets[[key]] <- asset
  collection_obj$assets <- assets

  write_stac(collection_obj, collection)

  cli::cli_alert_success(
    "Added {.field {key}} asset ({paste(roles, collapse = ', ')}) to {.path {collection}}"
  )

  invisible(collection)
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
#' cat <- tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni") 
#' col |>
#'   stac_add_collection(id = "lidar_ni_2023", title = "Lidar Solling 2023") |>
#'   stac_add_collection(id = "2023_q3", title = "Q3 2023 Data")
#' 
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*.laz")
#' items <- col |>
#'   stac_add_items(path = las_files)
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

  items <- vpc_to_stac_items(
    vpc_obj, collection_dir, items_dir, root_path, collection_id,
    root_title = root_link$title, collection_title = collection_obj$title
  )

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