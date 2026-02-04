# STAC Helper Functions
# Internal utilities for managing STAC catalogs and collections
# Part of the managelidar package

# I/O Operations ---------------------------------------------------------------

#' Read a STAC JSON file
#' @param path Path to STAC JSON file
#' @return List representing STAC object
#' @keywords internal
read_stac <- function(path) {
  if (!fs::file_exists(path)) {
    stop("STAC file does not exist: ", path)
  }
  yyjsonr::read_json_file(
    path,
    opts = yyjsonr::opts_read_json(df_missing_list_elem = "null")
  )
}

#' Write a STAC object to JSON file
#' @param obj STAC object (list)
#' @param path Output path
#' @return Invisible NULL
#' @keywords internal
write_stac <- function(obj, path) {
  jsonlite::write_json(
    x = obj,
    path = path,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  invisible()
}


# VPC Processing ---------------------------------------------------------------

#' Convert VPC features to STAC items
#' @param vpc_obj VPC object (list with $features)
#' @param collection_dir Path to collection directory
#' @param items_dir Path to items directory
#' @return List of STAC item objects
#' @keywords internal
vpc_to_stac_items <- function(vpc_obj, collection_dir, items_dir) {
  features <- vpc_obj$features

  # features is a data frame
  # Convert each row to a list item
  items <- lapply(seq_len(nrow(features)), function(i) {
    # Extract each column's value for row i
    item <- list(
      type = features$type[i],
      stac_version = features$stac_version[i],
      stac_extensions = features$stac_extensions[[i]],
      id = features$id[i],
      geometry = features$geometry[[i]],
      bbox = features$bbox[[i]],
      properties = features$properties[[i]],
      assets = features$assets[[i]]
    )

    # Set type to "Feature" and add links
    item$type <- "Feature"
    item$links <- build_item_links(item$id, items_dir, collection_dir)
    item
  })

  items
}

#' Extract spatial extent from VPC items
#' @param vpc_obj VPC object
#' @return List with spatial extent structure
#' @keywords internal
extract_spatial_extent <- function(vpc_obj) {
  features <- vpc_obj$features

  # features is a data frame, bbox is a list column
  # Each element of bbox is a numeric vector
  bboxes <- features$bbox

  list(
    bbox = list(
      c(
        min(sapply(bboxes, `[[`, 1)),  # xmin
        min(sapply(bboxes, `[[`, 2)),  # ymin
        min(sapply(bboxes, `[[`, 3)),  # zmin
        max(sapply(bboxes, `[[`, 4)),  # xmax
        max(sapply(bboxes, `[[`, 5)),  # ymax
        max(sapply(bboxes, `[[`, 6))   # zmax
      )
    )
  )
}

#' Extract temporal extent from VPC items
#' @param vpc_obj VPC object
#' @return List with temporal extent structure
#' @keywords internal
extract_temporal_extent <- function(vpc_obj) {
  features <- vpc_obj$features

  # features is a data frame, properties is a list column
  # Each element of properties is a list with datetime, pc:count, etc.
  datetimes <- sapply(features$properties, function(props) props$datetime)

  list(
    interval = list(
      list(
        min(datetimes),
        max(datetimes)
      )
    )
  )
}

#' Extract CRS from VPC items
#' @param vpc_obj VPC object
#' @return Integer CRS code
#' @keywords internal
extract_crs <- function(vpc_obj) {
  features <- vpc_obj$features

  # features is a data frame, properties is a list column
  # Each element of properties is a list with proj:epsg
  crs_values <- unique(sapply(features$properties, function(props) props$`proj:epsg`))

  # Should be single value (VPC is trusted to be valid)
  crs_values[1]
}


# Extent Merging ---------------------------------------------------------------

#' Merge two spatial extents
#' @param extent1 Spatial extent list (existing, bbox as matrix from yyjsonr)
#' @param extent2 Spatial extent list (new, bbox as list)
#' @return Merged spatial extent list
#' @keywords internal
merge_spatial_extents <- function(extent1, extent2) {
  # extent1 from yyjsonr has bbox as matrix, extent2 from our function has it as list
  bbox1 <- extent1$bbox[1, ]  # First row of matrix
  bbox2 <- extent2$bbox[[1]]  # First element of list

  list(
    bbox = list(
      c(
        min(bbox1[1], bbox2[1]),  # xmin
        min(bbox1[2], bbox2[2]),  # ymin
        min(bbox1[3], bbox2[3]),  # zmin
        max(bbox1[4], bbox2[4]),  # xmax
        max(bbox1[5], bbox2[5]),  # ymax
        max(bbox1[6], bbox2[6])   # zmax
      )
    )
  )
}

#' Merge two temporal extents
#' @param extent1 Temporal extent list (existing, interval as matrix from yyjsonr)
#' @param extent2 Temporal extent list (new, interval as list)
#' @return Merged temporal extent list
#' @keywords internal
merge_temporal_extents <- function(extent1, extent2) {
  # extent1 from yyjsonr has interval as matrix, extent2 from our function has it as list
  interval1 <- extent1$interval[1, ]  # First row of matrix
  interval2 <- extent2$interval[[1]]  # First element of list

  # Convert all to character for consistent comparison
  # Handle NA values
  dates <- c(
    as.character(interval1[1]),
    as.character(interval1[2]),
    as.character(interval2[[1]]),
    as.character(interval2[[2]])
  )

  # Remove NA values for min/max calculation
  dates <- dates[!is.na(dates) & dates != "NA"]

  list(
    interval = list(
      list(
        min(dates),
        max(dates)
      )
    )
  )
}


# Object Builders --------------------------------------------------------------

#' Build a catalog object structure
#' @param id Catalog ID
#' @param title Catalog title
#' @param description Catalog description
#' @return List with catalog structure (no links)
#' @keywords internal
build_catalog <- function(id, title, description) {
  list(
    id = id,
    type = "Catalog",
    stac_version = "1.0.0",
    title = title,
    description = description,
    links = list()
  )
}

#' Build a collection object structure
#' @param id Collection ID
#' @param title Collection title
#' @param description Collection description
#' @param extent Extent list with spatial and temporal
#' @param license License string
#' @param stac_extensions Character vector of extension URLs
#' @param keywords Character vector of keywords
#' @param providers List of provider objects
#' @param summaries List of summary objects
#' @param assets List of asset objects
#' @param ... Additional fields
#' @return List with collection structure (no links)
#' @keywords internal
build_collection <- function(
    id,
    title,
    description,
    extent,
    license,
    stac_extensions = c(
      "https://stac-extensions.github.io/pointcloud/v1.0.0/schema.json",
      "https://stac-extensions.github.io/projection/v1.1.0/schema.json"
    ),
    keywords = NULL,
    providers = NULL,
    summaries = NULL,
    assets = NULL,
    ...
) {
  collection_obj <- list(
    id = id,
    type = "Collection",
    stac_version = "1.0.0",
    title = title,
    description = description,
    license = license,
    stac_extensions = stac_extensions,
    extent = extent
  )

  # Add optional fields if provided
  if (!is.null(keywords)) collection_obj$keywords <- keywords
  if (!is.null(providers)) collection_obj$providers <- providers
  if (!is.null(summaries)) collection_obj$summaries <- summaries
  if (!is.null(assets)) collection_obj$assets <- assets

  # Add any additional fields from ...
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    collection_obj <- c(collection_obj, extra_fields)
  }

  # Initialize empty links
  collection_obj$links <- list()

  collection_obj
}


# Link Management --------------------------------------------------------------

#' Add a child link to parent object
#' @param parent_obj Parent STAC object (list)
#' @param child_rel_path Relative path to child from parent directory
#' @param child_title Optional title for the link
#' @return Updated parent object
#' @keywords internal
add_child_link <- function(parent_obj, child_rel_path, child_title = NULL) {
  # yyjsonr always returns links as a data frame
  # Convert data frame to list of lists
  links_list <- lapply(seq_len(nrow(parent_obj$links)), function(i) {
    link <- list(
      rel = parent_obj$links$rel[i],
      href = parent_obj$links$href[i],
      type = parent_obj$links$type[i]
    )
    # Add title if it exists and is not NA
    if ("title" %in% names(parent_obj$links) && !is.na(parent_obj$links$title[i])) {
      link$title <- parent_obj$links$title[i]
    }
    link
  })

  # Check if link already exists
  existing_hrefs <- sapply(links_list, function(link) link$href)
  if (child_rel_path %in% existing_hrefs) {
    return(parent_obj)  # Link already exists, skip
  }

  # Create new link
  new_link <- list(
    rel = "child",
    href = child_rel_path,
    type = "application/json"
  )

  if (!is.null(child_title)) {
    new_link$title <- child_title
  }

  # Add to links list
  parent_obj$links <- c(links_list, list(new_link))

  parent_obj
}

#' Build links for a STAC item
#' @param item_id Item ID
#' @param items_dir Path to items directory
#' @param collection_dir Path to collection directory
#' @return List of link objects
#' @keywords internal
build_item_links <- function(item_id, items_dir, collection_dir) {
  collection_file <- fs::path(collection_dir, "collection.json")

  list(
    list(
      rel = "self",
      href = fs::path(".", fs::path_rel(
        fs::path(items_dir, item_id, ext = "json"),
        items_dir
      )),
      type = "application/geo+json"
    ),
    list(
      rel = "collection",
      href = fs::path_rel(collection_file, items_dir),
      type = "application/json"
    ),
    list(
      rel = "parent",
      href = fs::path_rel(collection_file, items_dir),
      type = "application/json"
    )
  )
}

#' Build links for a collection
#' @param collection_dir Path to collection directory
#' @param parent_path Path to parent STAC file
#' @param items_dir Path to items directory
#' @return List of link objects
#' @keywords internal
build_collection_links <- function(collection_dir, parent_path, items_dir) {
  root_path <- find_root_catalog(parent_path)
  collection_file <- fs::path(collection_dir, "collection.json")

  list(
    list(
      rel = "root",
      href = fs::path_rel(root_path, collection_dir),
      type = "application/json"
    ),
    list(
      rel = "parent",
      href = fs::path_rel(parent_path, collection_dir),
      type = "application/json"
    ),
    list(
      rel = "self",
      href = fs::path_abs(collection_file),
      type = "application/json"
    ),
    list(
      rel = "items",
      href = fs::path(".", fs::path_rel(items_dir, collection_dir)),
      type = "application/geo+json"
    )
  )
}


# Path Helpers -----------------------------------------------------------------

#' Resolve collection directory based on parent type
#' @param parent_path Path to parent STAC file
#' @param collection_id Collection ID
#' @return Path to collection directory (created if needed)
#' @keywords internal
resolve_collection_dir <- function(parent_path, collection_id) {
  parent_obj <- read_stac(parent_path)
  parent_dir <- fs::path_dir(parent_path)

  if (get_stac_type(parent_obj) == "Catalog") {
    collection_dir <- fs::path(parent_dir, "collections", collection_id)
  } else {  # Collection (subcollection)
    collection_dir <- fs::path(parent_dir, collection_id)
  }

  fs::dir_create(collection_dir)
  collection_dir
}

#' Get items directory path
#' @param collection_dir Path to collection directory
#' @return Path to items directory
#' @keywords internal
get_items_dir <- function(collection_dir) {
  items_dir <- fs::path(collection_dir, "items")
  fs::dir_create(items_dir)
  items_dir
}

#' Find root catalog by following links
#' @param stac_path Path to any STAC file
#' @return Absolute path to root catalog
#' @keywords internal
find_root_catalog <- function(stac_path) {
  stac_obj <- read_stac(stac_path)
  stac_dir <- fs::path_dir(stac_path)

  # If no root link and is Catalog, this IS the root
  if (get_stac_type(stac_obj) == "Catalog") {
    return(fs::path_abs(stac_path))
  }

  # Look for root link
  # yyjsonr always returns links as a data frame
  root_rows <- which(stac_obj$links$rel == "root")
  if (length(root_rows) > 0) {
    root_href <- stac_obj$links$href[root_rows[1]]
    root_path <- fs::path_abs(root_href, start = stac_dir)
    return(root_path)
  }

  # If no root link and is Collection, error
  stop("Collection has no root link - malformed STAC structure")
}

#' Get STAC object type
#' @param stac_obj STAC object (list)
#' @return Character: "Catalog" or "Collection"
#' @keywords internal
get_stac_type <- function(stac_obj) {
  stac_obj$type
}


# Item Writing -----------------------------------------------------------------

#' Write STAC items to files
#' @param items List of STAC item objects
#' @param items_dir Path to items directory
#' @param overwrite Logical. If FALSE (default), skip existing items
#' @return Character vector of written item IDs
#' @keywords internal
write_items <- function(items, items_dir, overwrite = FALSE) {
  written_ids <- character()

  for (item in items) {
    item_path <- fs::path(items_dir, item$id, ext = "json")

    if (fs::file_exists(item_path) && !overwrite) {
      next  # Skip existing
    }

    write_stac(item, item_path)
    written_ids <- c(written_ids, item$id)
  }

  written_ids
}
