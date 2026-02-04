# STAC Management Functions
# User-facing functions for managing STAC catalogs and collections
# Part of the managelidar package

#' Add VPC items to STAC catalog or collection
#'
#' Add items from a Virtual Point Cloud (VPC) to a STAC catalog structure by
#' creating a new collection or updating an existing one. Collections can be
#' added directly to catalogs or nested under other collections.
#'
#' @param vpc Path to VPC file or VPC object (list with type="FeatureCollection")
#' @param parent Path to parent STAC JSON file (catalog.json or collection.json)
#' @param collection_info List with collection metadata for creating a new collection.
#'   Must include `id` field. Optional fields include: `title`, `description`,
#'   `license`, `keywords`, `providers`, `summaries`, `assets`, `stac_extensions`.
#' @param collection_path Path to existing collection.json for adding items to
#'   an existing collection.
#' @param overwrite_items Logical. If `TRUE`, overwrite existing item files.
#'   Default is `FALSE` (skip existing items).
#'
#' @details
#' Exactly one of `collection_info` or `collection_path` must be provided.
#'
#' When creating a new collection (`collection_info`), the function:
#' \itemize{
#'   \item Extracts spatial and temporal extent from VPC items
#'   \item Extracts CRS information
#'   \item Creates collection structure with proper links
#'   \item Writes items to the items/ subdirectory
#'   \item Updates parent with a child link
#' }
#'
#' When updating an existing collection (`collection_path`), the function:
#' \itemize{
#'   \item Merges new spatial/temporal extents with existing
#'   \item Writes new items (skipping existing unless overwrite_items=TRUE)
#'   \item Updates collection metadata
#' }
#'
#' Directory structure created:
#' \itemize{
#'   \item For catalog parent: `{parent_dir}/collections/{collection_id}/`
#'   \item For collection parent: `{parent_dir}/{collection_id}/` (subcollection)
#' }
#'
#' @return Path to the collection file (invisibly)
#'
#' @examples
#' \dontrun{
#' # Create new collection in catalog
#' coll_info <- list(
#'   id = "lidar_ni_2023",
#'   title = "Lidar Daten Solling 2023",
#'   description = "ALS data collection in Solling 2023",
#'   license = "proprietary",
#'   keywords = c("ALS", "Lidar", "Niedersachsen"),
#'   summaries = list(
#'     platform = "Airplane",
#'     `pc:density` = 25
#'   )
#' )
#'
#' stac_add(
#'   vpc = "path/to/data.vpc",
#'   parent = "path/to/catalog.json",
#'   collection_info = coll_info
#' )
#'
#' # Add items to existing collection
#' stac_add(
#'   vpc = "path/to/new_data.vpc",
#'   parent = "path/to/catalog.json",
#'   collection_path = "path/to/catalog/collections/lidar_ni_2023/collection.json"
#' )
#'
#' # Create subcollection
#' subcoll_info <- list(
#'   id = "2023_q3",
#'   title = "Q3 2023 Data",
#'   description = "Data collected in Q3 2023",
#'   license = "proprietary"
#' )
#'
#' stac_add(
#'   vpc = "path/to/q3_data.vpc",
#'   parent = "path/to/catalog/collections/lidar_ni_2023/collection.json",
#'   collection_info = subcoll_info
#' )
#' }
#'
#' @export
stac_add <- function(
    vpc,
    parent,
    collection_info = NULL,
    collection_path = NULL,
    overwrite_items = FALSE
) {

  # Validate inputs ------------------------------------------------------------

  # Exactly one of collection_info or collection_path must be provided
  if (is.null(collection_info) && is.null(collection_path)) {
    stop("Either collection_info or collection_path must be provided")
  }

  if (!is.null(collection_info) && !is.null(collection_path)) {
    stop("Only one of collection_info or collection_path can be provided")
  }

  # Validate parent exists
  if (!fs::file_exists(parent)) {
    stop("Parent STAC file does not exist: ", parent)
  }

  # Validate collection_info has id if creating new collection
  if (!is.null(collection_info) && is.null(collection_info$id)) {
    stop("collection_info must contain an 'id' field")
  }

  # Validate collection_path exists if provided
  if (!is.null(collection_path) && !fs::file_exists(collection_path)) {
    stop("collection_path does not exist: ", collection_path)
  }


  # Resolve VPC ----------------------------------------------------------------

  vpc_obj <- resolve_vpc(vpc)


  # Read parent ----------------------------------------------------------------

  parent_obj <- read_stac(parent)


  # Determine collection directory and paths ----------------------------------

  if (!is.null(collection_info)) {
    # Creating new collection
    collection_id <- collection_info$id
    collection_dir <- resolve_collection_dir(parent, collection_id)
    collection_file <- fs::path(collection_dir, "collection.json")

    # Check if collection already exists
    if (fs::file_exists(collection_file)) {
      message("Collection already exists: ", collection_file)
      message("To add items to this collection, use collection_path instead of collection_info")
      return(invisible(collection_file))
    }

  } else {
    # Adding to existing collection
    collection_file <- collection_path
    collection_dir <- fs::path_dir(collection_file)
  }

  items_dir <- get_items_dir(collection_dir)


  # Extract metadata from VPC --------------------------------------------------

  spatial_extent <- extract_spatial_extent(vpc_obj)
  temporal_extent <- extract_temporal_extent(vpc_obj)
  crs <- extract_crs(vpc_obj)


  # Build or update collection -------------------------------------------------

  if (!is.null(collection_info)) {
    # Create new collection

    # Build extent
    extent <- list(
      spatial = spatial_extent,
      temporal = temporal_extent
    )

    # Build summaries (add CRS and pc:type)
    summaries <- collection_info$summaries
    if (is.null(summaries)) {
      summaries <- list()
    }
    summaries$`proj:epsg` <- list(crs)
    summaries$`pc:type` <- list("lidar")

    # Build collection object
    collection_obj <- build_collection(
      id = collection_info$id,
      title = collection_info$title %||% collection_info$id,
      description = collection_info$description %||% "",
      extent = extent,
      license = collection_info$license %||% "proprietary",
      stac_extensions = collection_info$stac_extensions,
      keywords = collection_info$keywords,
      providers = collection_info$providers,
      summaries = summaries,
      assets = collection_info$assets
    )

  } else {
    # Update existing collection

    collection_obj <- read_stac(collection_file)

    # Merge extents
    collection_obj$extent$spatial <- merge_spatial_extents(
      collection_obj$extent$spatial,
      spatial_extent
    )

    collection_obj$extent$temporal <- merge_temporal_extents(
      collection_obj$extent$temporal,
      temporal_extent
    )
  }


  # Convert VPC items to STAC items --------------------------------------------

  items <- vpc_to_stac_items(vpc_obj, collection_dir, items_dir)


  # Write items ----------------------------------------------------------------

  written_ids <- write_items(items, items_dir, overwrite = overwrite_items)

  skipped_count <- length(items) - length(written_ids)

  if (length(written_ids) > 0) {
    message("Wrote ", length(written_ids), " items to ", items_dir)
  }

  if (skipped_count > 0) {
    message("Skipped ", skipped_count, " existing items (use overwrite_items = TRUE to replace)")
  }

  if (length(written_ids) == 0 && skipped_count == 0) {
    message("No items to write")
  }


  # Build collection links -----------------------------------------------------

  collection_obj$links <- build_collection_links(
    collection_dir,
    parent,
    items_dir
  )


  # Write collection -----------------------------------------------------------

  write_stac(collection_obj, collection_file)


  # Update parent with child link ----------------------------------------------

  child_rel_path <- fs::path(".", fs::path_rel(collection_file, fs::path_dir(parent)))
  parent_obj <- add_child_link(
    parent_obj,
    child_rel_path,
    child_title = collection_obj$title
  )

  write_stac(parent_obj, parent)


  # Return ---------------------------------------------------------------------

  if (length(written_ids) > 0) {
    message("Successfully updated collection: ", collection_file)
  } else if (skipped_count > 0) {
    message("Collection unchanged (all items already exist): ", collection_file)
  } else {
    message("Collection processed: ", collection_file)
  }

  invisible(collection_file)
}


#' Null coalescing operator
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
