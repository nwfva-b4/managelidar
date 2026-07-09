# STAC Helper Functions
# Internal utilities for managing STAC catalogs and collections
# Part of the managelidar package

# I/O Operations ---------------------------------------------------------------

#' Read a STAC JSON file
#'
#' Links are normalized to a plain list of link objects via
#' [normalize_links()], regardless of yyjsonr's internal data-frame
#' representation. This prevents optional fields (like `title`) that are
#' absent on some links from round-tripping back out as explicit `null`
#' values when the object is later written with [write_stac()].
#'
#' @param path Path to STAC JSON file
#' @return List representing STAC object
#' @keywords internal
read_stac <- function(path) {
  if (!fs::file_exists(path)) {
    stop("STAC file does not exist: ", path)
  }
  obj <- yyjsonr::read_json_file(
    path,
    opts = yyjsonr::opts_read_json(df_missing_list_elem = "null")
  )
  if (!is.null(obj$links)) {
    obj$links <- normalize_links(obj$links)
  }
  obj
}

#' Write a STAC object to JSON file
#' @param obj STAC object (list)
#' @param path Output path
#' @return Invisible NULL
#' @keywords internal
write_stac <- function(obj, path) {
  yyjsonr::write_json_file(
    x = obj,
    filename = path,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  invisible()
}



path_to_file_uri <- function(path) {
  # normalize separators
  path <- gsub("\\\\", "/", path)

  # Windows drive letter?
  if (grepl("^[A-Za-z]:/", path)) {
    paste0("file:///", path)
  } else if (startsWith(path, "/")) {
    paste0("file://", path)
  } else {
    path
  }
}

# VPC Processing ---------------------------------------------------------------

#' Convert VPC features to STAC items
#' @param vpc_obj VPC object (list with $features)
#' @param collection_dir Path to collection directory
#' @param items_dir Path to items directory
#' @param root_path Absolute path to root catalog
#' @param collection_id Parent collection ID
#' @return List of STAC item objects
#' @keywords internal
vpc_to_stac_items <- function(vpc_obj, collection_dir, items_dir, root_path, collection_id) {
  features <- vpc_obj$features

  items <- lapply(seq_len(nrow(features)), function(i) {

    assets <- features$assets[[i]]

    # Convert asset hrefs to file URIs
    for (name in names(assets)) {
      if (!is.null(assets[[name]]$href)) {
        assets[[name]]$href <- path_to_file_uri(assets[[name]]$href)
      }

      # Ensure roles is an array
      if (!is.null(assets[[name]]$roles) &&
          is.character(assets[[name]]$roles) &&
          length(assets[[name]]$roles) == 1) {
        assets[[name]]$roles <- list(assets[[name]]$roles)
      }
    }

    item <- list(
      type = "Feature",
      collection = collection_id,
      # lasR writes v.1.0.0, we manually bump it here
      # stac_version = features$stac_version[i],
      stac_version = "1.1.0",
      # Override whatever extension versions the VPC source data declares
      # (e.g. lasR bakes in pointcloud v1.0.0) so items always match the
      # versions this package targets - see required_lidar_stac_extensions().
      stac_extensions = required_lidar_stac_extensions(),
      # stac_extensions = features$stac_extensions[[i]],
      id = features$id[i],
      geometry = features$geometry[[i]],
      bbox = features$bbox[[i]],
      properties = features$properties[[i]],
      assets = assets
    )

    item$links <- build_item_links(item$id, items_dir, collection_dir, root_path)
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
        min(sapply(bboxes, `[[`, 1)), # xmin
        min(sapply(bboxes, `[[`, 2)), # ymin
        min(sapply(bboxes, `[[`, 3)), # zmin
        max(sapply(bboxes, `[[`, 4)), # xmax
        max(sapply(bboxes, `[[`, 5)), # ymax
        max(sapply(bboxes, `[[`, 6)) # zmax
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
  bbox1 <- extent1$bbox[1, ] # First row of matrix
  bbox2 <- extent2$bbox[[1]] # First element of list

  list(
    bbox = list(
      c(
        min(bbox1[1], bbox2[1]), # xmin
        min(bbox1[2], bbox2[2]), # ymin
        min(bbox1[3], bbox2[3]), # zmin
        max(bbox1[4], bbox2[4]), # xmax
        max(bbox1[5], bbox2[5]), # ymax
        max(bbox1[6], bbox2[6]) # zmax
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
  interval1 <- extent1$interval[1, ] # First row of matrix
  interval2 <- extent2$interval[[1]] # First element of list

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
    stac_version = "1.1.0",
    title = title,
    description = description,
    links = list()
  )
}

#' STAC extensions required whenever pointcloud/projection fields
#' (`proj:epsg`, `pc:type`) are present on a collection's summaries.
#' @return Character vector of extension schema URLs
#' @keywords internal
required_lidar_stac_extensions <- function() {
  c(
    "https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json",
    "https://stac-extensions.github.io/projection/v1.1.0/schema.json"
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
  stac_extensions = required_lidar_stac_extensions(),
  keywords = NULL,
  providers = NULL,
  summaries = NULL,
  assets = NULL,
  ...
) {
  collection_obj <- list(
    id = id,
    type = "Collection",
    stac_version = "1.1.0",
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

#' Normalize a links structure into a plain list of link objects
#'
#' yyjsonr represents an array of link objects as a data frame when read
#' from disk, filling any field missing on a given link (e.g. `title`) with
#' an explicit `NULL` (per `df_missing_list_elem = "null"`). Serializing
#' that data frame back out would emit those as literal `"title": null`,
#' which is invalid for a STAC link (`title` must be a string or absent).
#' This function converts either representation into a uniform list of
#' named lists, dropping NA/NULL optional fields entirely so a link is
#' either a proper string or not present in the output at all.
#'
#' @param links Links as returned by [read_stac()] (data frame) or already
#'   a list of link objects
#' @return List of link objects (named lists), never containing NA/NULL
#'   field values
#' @keywords internal
normalize_links <- function(links) {
  if (is.null(links) || length(links) == 0) {
    return(list())
  }

  is_empty_value <- function(v) length(v) == 0 || (length(v) == 1 && is.na(v))

  if (is.data.frame(links)) {
    lapply(seq_len(nrow(links)), function(i) {
      link <- list()
      for (col in names(links)) {
        val <- links[[col]][[i]]
        if (is_empty_value(val)) next
        link[[col]] <- val
      }
      link
    })
  } else {
    lapply(links, function(link) {
      link[!vapply(link, is_empty_value, logical(1))]
    })
  }
}

#' Find the first link with a given `rel` value
#' @param links List of link objects (as returned by [read_stac()])
#' @param rel Relation type to search for (e.g. `"root"`, `"parent"`)
#' @return The matching link object, or `NULL` if none found
#' @keywords internal
find_link <- function(links, rel) {
  for (link in links) {
    if (identical(link$rel, rel)) return(link)
  }
  NULL
}

#' Add a child link to parent object
#' @param parent_obj Parent STAC object (list)
#' @param child_rel_path Relative path to child from parent directory
#' @param child_title Optional title for the link
#' @return Updated parent object
#' @keywords internal
add_child_link <- function(parent_obj, child_rel_path, child_title = NULL) {
  existing_hrefs <- vapply(parent_obj$links, function(link) link$href, character(1))
  if (child_rel_path %in% existing_hrefs) {
    return(parent_obj) # Link already exists, skip
  }

  new_link <- list(
    rel = "child",
    href = child_rel_path,
    type = "application/json"
  )

  if (!is.null(child_title)) {
    new_link$title <- child_title
  }

  parent_obj$links <- c(parent_obj$links, list(new_link))

  parent_obj
}

#' Build links for a STAC item
#' @param item_id Item ID
#' @param items_dir Path to items directory
#' @param collection_dir Path to collection directory
#' @param root_path Absolute path to root catalog
#' @return List of link objects
#' @keywords internal
build_item_links <- function(item_id, items_dir, collection_dir, root_path) {
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
      rel = "root",
      href = fs::path_rel(root_path, items_dir),
      type = "application/json"
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
#'
#' Note: does not include an `items` link pointing at the items directory.
#' That convention is for a live OGC API - Features endpoint that returns a
#' `FeatureCollection` on request; a static file server just exposes the
#' raw directory, which STAC clients can't use. Static catalogs instead
#' list each item individually via `rel: "item"` links - see
#' [rebuild_item_links()], called from [stac_add_items()].
#'
#' @param collection_dir Path to collection directory
#' @param parent_path Path to parent STAC file
#' @return List of link objects
#' @keywords internal
build_collection_links <- function(collection_dir, parent_path) {
  root_path <- find_root_catalog(parent_path)

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
      href = fs::path(".", "collection.json"),
      type = "application/json"
    )
  )
}

#' Build links for a root catalog
#' @param catalog_file Path to catalog.json
#' @param catalog_dir Path to catalog directory
#' @return List of link objects
#' @keywords internal
build_catalog_links <- function(catalog_file, catalog_dir) {
  list(
    list(
      rel = "root",
      href = fs::path(".", fs::path_rel(catalog_file, catalog_dir)),
      type = "application/json"
    ),
    list(
      rel = "self",
      href = fs::path(".", "catalog.json"),
      type = "application/json"
    )
  )
}

#' Rebuild a collection's `item` links from the files present in items_dir
#'
#' Static STAC catalogs list each item directly on the collection via
#' `rel: "item"` links (the item-level equivalent of `rel: "child"` for
#' sub-collections). This re-derives that set from the items actually on
#' disk, so it stays correct across repeated [stac_add_items()] calls
#' (including ones using `overwrite_items`) without accumulating stale or
#' duplicate entries.
#'
#' @param links Existing links list; non-`item` links are preserved as-is
#' @param collection_dir Path to collection directory
#' @param items_dir Path to items directory
#' @return Updated links list
#' @keywords internal
rebuild_item_links <- function(links, collection_dir, items_dir) {
  links <- Filter(function(link) !identical(link$rel, "item"), links)

  item_files <- fs::dir_ls(items_dir, glob = "*.json", fail = FALSE)

  item_links <- lapply(item_files, function(f) {
    list(
      rel = "item",
      href = fs::path(".", fs::path_rel(f, collection_dir)),
      type = "application/geo+json",
      title = fs::path_ext_remove(fs::path_file(f))
    )
  })
  names(item_links) <- NULL

  c(links, item_links)
}

#' Build an empty placeholder extent for a newly created collection
#'
#' Spatial bbox has no valid "unknown" representation in STAC (must be
#' numeric), so a zero bbox is used as a clearly-empty placeholder.
#' Temporal interval bounds may legally be `NULL` per the STAC spec, meaning
#' "unknown". Both are meant to be replaced (not merged) the first time
#' items are added via [stac_add_items()].
#'
#' @return List with placeholder spatial and temporal extent
#' @keywords internal
empty_extent <- function() {
  list(
    spatial = list(bbox = list(c(0, 0, 0, 0, 0, 0))),
    temporal = list(interval = list(list(NULL, NULL)))
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
  } else { # Collection (subcollection)
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

#' Check whether a collection's extent is still the empty placeholder
#' written by stac_add_collection() (as opposed to a real extent derived
#' from items). Only the spatial bbox is checked, since a zero bbox is the
#' only placeholder signal available (STAC does not allow `null` bbox
#' values, unlike temporal intervals).
#' @param extent Extent list as read from disk (bbox as matrix)
#' @return Logical
#' @keywords internal
extent_is_placeholder <- function(extent) {
  bbox <- extent$spatial$bbox
  bbox <- if (is.matrix(bbox)) bbox[1, ] else bbox[[1]]
  isTRUE(all(bbox == 0))
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

  root_link <- find_link(stac_obj$links, "root")
  if (!is.null(root_link)) {
    return(fs::path_abs(root_link$href, start = stac_dir))
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
      next # Skip existing
    }

    write_stac(item, item_path)
    written_ids <- c(written_ids, item$id)
  }

  written_ids
}