# STAC Helper Functions
# Internal utilities for managing STAC catalogs and collections
# Part of the managelidar package

#' Current time as an RFC 3339 / STAC-compliant UTC timestamp
#' @return Character, e.g. `"2026-07-15T14:32:07Z"`
#' @keywords internal
stac_timestamp <- function() {
  strftime(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Recursively strip the `fs_path` S3 class from any values in a STAC
#' object
#'
#' Hrefs built via `fs::path()`/`fs::path_rel()` carry an `fs_path` class
#' on top of the underlying character value. The same href read back from
#' JSON after a round-trip (via [read_stac()]) has no such class - so a
#' plain `identical()` between a freshly-rebuilt object (fs_path hrefs)
#' and one just read from disk (plain character hrefs) reports "changed"
#' even when every string value actually matches. Every change-detection
#' comparison in this package runs both sides through this first, the
#' same way [extents_equal()] normalizes away the matrix-vs-list
#' representation difference for extents.
#'
#' @param x Any R object (typically a STAC list structure)
#' @return The same structure with `fs_path` classing removed
#' @keywords internal
strip_fs_path <- function(x) {
  if (inherits(x, "fs_path")) {
    return(unclass(x))
  }
  if (is.list(x)) {
    return(lapply(x, strip_fs_path))
  }
  x
}

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
#' @param root_title Title of the root catalog
#' @param collection_title Title of the owning collection
#' @return List of STAC item objects
#' @keywords internal
vpc_to_stac_items <- function(vpc_obj, collection_dir, items_dir, root_path, collection_id, root_title, collection_title) {
  features <- vpc_obj$features

  items <- lapply(seq_len(nrow(features)), function(i) {

    assets <- features$assets[[i]]

    if (is.data.frame(assets)) {
      assets <- lapply(names(assets), function(x) {
    as.list(assets[[x]])
  })
  names(assets) <- names(features$assets[[i]])
}

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
      stac_version = features$stac_version[i],
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

    # created/updated (STAC Common Metadata). If this item already exists
    # on disk (e.g. this batch is being written with overwrite_items =
    # TRUE), keep its original created timestamp rather than resetting it -
    # only updated should move.
    item_path <- fs::path(items_dir, item$id, ext = "json")
    if (fs::file_exists(item_path)) {
      existing <- tryCatch(read_stac(item_path), error = function(e) NULL)
      item$properties$created <- existing$properties$created %||% stac_timestamp()
    } else {
      item$properties$created <- stac_timestamp()
    }
    item$properties$updated <- stac_timestamp()

    item$links <- build_item_links(
      item$id, items_dir, collection_dir, root_path, root_title, collection_title
    )
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
    stac_version = "1.0.0",
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

#' Replace the link with a given `rel`, or add it if not present
#'
#' For relation types that should only appear once per object (`root`,
#' `parent`, `self`, `icon`). Not suitable for `child`/`item` links, which
#' are multi-valued - see [add_child_link()] and [rebuild_item_links()]
#' for those.
#'
#' Replaces in place (at the existing link's position) rather than
#' removing and re-appending, so a call that doesn't actually change
#' anything doesn't reorder the links list either - that reordering would
#' otherwise make before/after equality checks (used to detect whether a
#' write is actually needed) report a change that isn't really there.
#'
#' @param links List of link objects
#' @param new_link The link object to set (its `rel` determines what gets
#'   replaced)
#' @return Updated links list
#' @keywords internal
set_link <- function(links, new_link) {
  idx <- NULL
  for (i in seq_along(links)) {
    if (identical(links[[i]]$rel, new_link$rel)) {
      idx <- i
      break
    }
  }

  if (!is.null(idx)) {
    links[[idx]] <- new_link
  } else {
    links <- c(links, list(new_link))
  }

  links
}

#' Add or update a child link on a parent object
#'
#' If a child link with this href already exists, its title is updated in
#' place (so renaming a collection also updates its listing in the
#' parent); otherwise a new child link is appended.
#'
#' Hrefs are compared as plain character strings (via `as.character()`),
#' not with `identical()`. A freshly built href from `fs::path()` carries
#' an `fs_path` S3 class, but an href read back from JSON via
#' [read_stac()] is a plain character string after the round-trip -
#' `identical()` treats those as different even when the string content
#' matches, which silently defeated this match on every call after the
#' first (each "update" appended a duplicate child link instead).
#'
#' @param parent_obj Parent STAC object (list)
#' @param child_rel_path Relative path to child from parent directory
#' @param child_title Optional title for the link
#' @return Updated parent object
#' @keywords internal
add_child_link <- function(parent_obj, child_rel_path, child_title = NULL) {
  new_link <- list(rel = "child", href = child_rel_path, type = "application/json")
  if (!is.null(child_title)) new_link$title <- child_title

  target_href <- as.character(child_rel_path)

  existing_idx <- NULL
  for (i in seq_along(parent_obj$links)) {
    link <- parent_obj$links[[i]]
    if (identical(link$rel, "child") && identical(as.character(link$href), target_href)) {
      existing_idx <- i
      break
    }
  }

  if (!is.null(existing_idx)) {
    parent_obj$links[[existing_idx]] <- new_link
  } else {
    parent_obj$links <- c(parent_obj$links, list(new_link))
  }

  parent_obj
}

#' Build links for a STAC item
#' @param item_id Item ID
#' @param items_dir Path to items directory
#' @param collection_dir Path to collection directory
#' @param root_path Absolute path to root catalog
#' @param root_title Title of the root catalog
#' @param collection_title Title of the owning collection
#' @return List of link objects
#' @keywords internal
build_item_links <- function(item_id, items_dir, collection_dir, root_path, root_title, collection_title) {
  collection_file <- fs::path(collection_dir, "collection.json")

  list(
    list(
      rel = "self",
      href = fs::path(".", fs::path_rel(
        fs::path(items_dir, item_id, ext = "json"),
        items_dir
      )),
      type = "application/geo+json",
      title = item_id
    ),
    list(
      rel = "root",
      href = fs::path_rel(root_path, items_dir),
      type = "application/json",
      title = root_title
    ),
    list(
      rel = "collection",
      href = fs::path_rel(collection_file, items_dir),
      type = "application/json",
      title = collection_title
    ),
    list(
      rel = "parent",
      href = fs::path_rel(collection_file, items_dir),
      type = "application/json",
      title = collection_title
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
#' @param title Title of this collection (used on its own `self` link)
#' @return List of link objects
#' @keywords internal
build_collection_links <- function(collection_dir, parent_path, title) {
  root_path <- find_root_catalog(parent_path)
  root_obj <- read_stac(root_path)
  parent_obj <- read_stac(parent_path)

  list(
    list(
      rel = "root",
      href = fs::path_rel(root_path, collection_dir),
      type = "application/json",
      title = root_obj$title
    ),
    list(
      rel = "parent",
      href = fs::path_rel(parent_path, collection_dir),
      type = "application/json",
      title = parent_obj$title
    ),
    list(
      rel = "self",
      href = fs::path(".", "collection.json"),
      type = "application/json",
      title = title
    )
  )
}

#' Build links for a root catalog
#' @param catalog_file Path to catalog.json
#' @param catalog_dir Path to catalog directory
#' @param title Title of this catalog
#' @return List of link objects
#' @keywords internal
build_catalog_links <- function(catalog_file, catalog_dir, title) {
  list(
    list(
      rel = "root",
      href = fs::path(".", fs::path_rel(catalog_file, catalog_dir)),
      type = "application/json",
      title = title
    ),
    list(
      rel = "self",
      href = fs::path(".", "catalog.json"),
      type = "application/json",
      title = title
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


#' Guess the media type of an image from its file extension
#'
#' Strips any URL query string/fragment before checking the extension, so
#' this works for both local paths and URLs.
#'
#' @param path Path or URL to an image file
#' @return Character media type, or `NULL` (with a warning) if the
#'   extension isn't recognized
#' @keywords internal
guess_image_media_type <- function(path) {
  clean <- sub("[?#].*$", "", path)
  ext <- tolower(fs::path_ext(clean))
  type <- switch(
    ext,
    png = "image/png",
    jpg = ,
    jpeg = "image/jpeg",
    webp = "image/webp",
    gif = "image/gif",
    tif = ,
    tiff = "image/tiff; application=geotiff",
    NULL
  )
  if (is.null(type)) {
    cli::cli_alert_warning("Could not determine media type for {.path {path}}; omitting {.field type}")
  }
  type
}

#' Resolve an image source (local path or URL) into an href usable in a
#' STAC link or asset, optionally copying it into the catalog tree first
#'
#' Local files default to being copied into `{containing_dir}/assets/`,
#' since a bare local path (or even a `file://` URI) can't be loaded by a
#' browser viewing the catalog through [stac_browse()]. URLs default to
#' being referenced in place, since they're already web-accessible; pass
#' `copy = TRUE` to download and vendor them into the catalog instead (so
#' the catalog keeps working even if the original URL later goes away).
#'
#' @param source A URL (`http://`/`https://`), or a path to a local image
#'   file
#' @param containing_dir Directory of the catalog/collection file this
#'   image is being attached to; hrefs are made relative to this
#' @param key Base filename (without extension) to use if the image is
#'   copied/downloaded
#' @param copy Logical, or `NULL` to use the default described above
#' @return List with `href` (character) and `type` (character or `NULL`)
#' @keywords internal
resolve_image_asset <- function(source, containing_dir, key, copy = NULL) {
  is_url <- grepl("^https?://", source)

  if (is_url) {
    copy <- copy %||% FALSE
    if (!copy) {
      return(list(href = source, type = guess_image_media_type(source)))
    }

    dest_dir <- fs::path(containing_dir, "assets")
    fs::dir_create(dest_dir)
    ext <- fs::path_ext(sub("[?#].*$", "", source))
    if (ext == "") ext <- "png" # best-effort default when the URL has none
    dest_file <- fs::path(dest_dir, key, ext = ext)

    result <- tryCatch(
      utils::download.file(source, dest_file, mode = "wb", quiet = TRUE),
      error = function(e) cli::cli_abort("Failed to download {.url {source}}: {conditionMessage(e)}")
    )

    return(list(
      href = fs::path(".", fs::path_rel(dest_file, containing_dir)),
      type = guess_image_media_type(dest_file)
    ))
  }

  if (!fs::file_exists(source)) {
    cli::cli_abort("Image file does not exist: {.path {source}}")
  }

  copy <- copy %||% TRUE
  if (!copy) {
    cli::cli_alert_warning(
      "Referencing local image without copying - it won't be viewable via {.fn stac_browse}"
    )
    return(list(
      href = path_to_file_uri(fs::path_abs(source)),
      type = guess_image_media_type(source)
    ))
  }

  dest_dir <- fs::path(containing_dir, "assets")
  fs::dir_create(dest_dir)
  dest_file <- fs::path(dest_dir, key, ext = fs::path_ext(source))
  fs::file_copy(source, dest_file, overwrite = TRUE)

  list(
    href = fs::path(".", fs::path_rel(dest_file, containing_dir)),
    type = guess_image_media_type(dest_file)
  )
}

#' Compare two extents by value, ignoring internal representation
#'
#' An extent read from disk via [read_stac()] has its bbox/interval as a
#' matrix; a freshly computed one (from [extract_spatial_extent()],
#' [merge_spatial_extents()], etc.) has them as a list. A plain
#' `identical()` on the two would report "different" even when the actual
#' coordinates/dates match, purely due to representation - this compares
#' the underlying values instead.
#'
#' @param extent1,extent2 Extent objects to compare
#' @return Logical
#' @keywords internal
extents_equal <- function(extent1, extent2) {
  normalize_bbox <- function(bbox) {
    unname(if (is.matrix(bbox)) bbox[1, ] else bbox[[1]])
  }
  normalize_interval <- function(interval) {
    as.character(unname(if (is.matrix(interval)) interval[1, ] else unlist(interval[[1]])))
  }

  isTRUE(all(normalize_bbox(extent1$spatial$bbox) == normalize_bbox(extent2$spatial$bbox))) &&
    identical(normalize_interval(extent1$temporal$interval), normalize_interval(extent2$temporal$interval))
}

#' Build a combined VPC (Virtual Point Cloud) FeatureCollection from every
#' item in a collection's items directory
#'
#' [vpc_to_stac_items()] builds each item by taking a VPC feature and
#' adding STAC-specific fields on top (`links`, `collection`). This
#' reverses that: strips those two fields back off, leaving the original
#' VPC feature shape (`type`/`stac_version`/`stac_extensions`/`id`/
#' `geometry`/`bbox`/`properties`/`assets`) - so the result is a valid VPC
#' representing every item currently in the collection.
#'
#' @param items_dir Path to items directory
#' @return A list representing a VPC FeatureCollection
#' @keywords internal
build_combined_vpc <- function(items_dir) {
  item_files <- fs::dir_ls(items_dir, glob = "*.json", fail = FALSE)

  features <- lapply(item_files, function(f) {
    item_obj <- read_stac(f)
    item_obj$links <- NULL
    item_obj$collection <- NULL
    item_obj
  })
  names(features) <- NULL

  list(type = "FeatureCollection", features = features)
}

#' Recompute and register a collection's combined VPC asset
#'
#' Writes `{collection_dir}/assets/collection.vpc` and registers it under
#' `collection_obj$assets$vpc`. Since this is derived from the items
#' themselves (not user-supplied), it's meant to be called automatically
#' whenever items change (see [stac_add_items()]).
#'
#' @param collection_obj Collection object (list); `$assets` is updated
#' @param collection_dir Path to collection directory
#' @param items_dir Path to items directory
#' @return List with `collection_obj` (updated) and `vpc` (the combined
#'   VPC object, for reuse by [update_footprints_asset()] without
#'   re-reading every item file a second time)
#' @keywords internal
update_vpc_asset <- function(collection_obj, collection_dir, items_dir) {
  vpc <- build_combined_vpc(items_dir)

  assets_dir <- fs::path(collection_dir, "assets")
  fs::dir_create(assets_dir)
  vpc_file <- fs::path(assets_dir, "collection", ext = "vpc")
  write_stac(vpc, vpc_file)

  assets <- collection_obj$assets
  if (is.null(assets)) assets <- list()
  assets$vpc <- list(
    href = as.character(fs::path(".", fs::path_rel(vpc_file, collection_dir))),
    title = "Virtual Point Cloud",
    type = "application/json",
    roles = list("metadata", "index")
  )
  collection_obj$assets <- assets

  list(collection_obj = collection_obj, vpc = vpc)
}

#' Recompute and register a collection's footprints GeoPackage asset
#'
#' Reuses [write_gpkg()] to convert the combined VPC (from
#' [update_vpc_asset()]) into a queryable GeoPackage - one feature per
#' item, with its footprint geometry and metadata as attributes, unlike a
#' plain GeoJSON where per-tile attributes aren't easily queryable in GIS
#' software.
#'
#' Deletes any existing file at the destination first: [write_gpkg()]
#' checks its own `overwrite` argument before writing, but doesn't delete
#' the existing file itself, and `sf::st_write()` can otherwise behave
#' ambiguously (refuse, or append a duplicate layer) when the destination
#' GeoPackage already exists - which it will, since this gets called
#' again on the same path every time items are added.
#'
#' @param collection_obj Collection object (list); `$assets` is updated
#' @param collection_dir Path to collection directory
#' @param vpc The combined VPC object, as returned by
#'   [update_vpc_asset()]
#' @param crs EPSG code to reproject the footprints to (the collection's
#'   own CRS)
#' @return Updated `collection_obj`
#' @keywords internal
update_footprints_asset <- function(collection_obj, collection_dir, vpc, crs) {
  assets_dir <- fs::path(collection_dir, "assets")
  fs::dir_create(assets_dir)
  gpkg_file <- fs::path(assets_dir, "footprints", ext = "gpkg")

  if (fs::file_exists(gpkg_file)) fs::file_delete(gpkg_file)
  write_gpkg(vpc, out_file = gpkg_file, overwrite = TRUE, crs = crs, metrics = NULL)

  assets <- collection_obj$assets
  if (is.null(assets)) assets <- list()
  assets$footprints <- list(
    href = as.character(fs::path(".", fs::path_rel(gpkg_file, collection_dir))),
    title = "Item Footprints",
    type = "application/geopackage+sqlite3",
    roles = list("footprints")
  )
  collection_obj$assets <- assets

  collection_obj
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