#' Filter point cloud files by spatial extent
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param extent Spatial extent to filter by. Can be:
#'   \itemize{
#'     \item Numeric vector of length 2 (point: x, y) or 4 (bbox: xmin, ymin, xmax, ymax)
#'     \item sf/sfc object (point, multipoint, polygon, bbox)
#'   }
#' @param crs Character or numeric. Coordinate reference system of the extent.
#'   If NULL (default) and extent is numeric, assumes extent is in the same CRS
#'   as the VPC features. Required for sf objects without CRS.
#'   Can be EPSG code (e.g., 4326, 25832) or WKT2 string.
#' @param out_file Optional. Path where the filtered VPC should be saved.
#'   If NULL (default), returns the VPC as an R object.
#'   If provided, saves to file and returns the file path.
#'   Must have `.vpc` extension and must not already exist.
#'   File is only created if filtering returns results.
#'
#' @return If `out_file` is NULL, returns a VPC object (list) containing only
#'   features that intersect the extent. If `out_file` is provided and results
#'   exist, returns the path to the saved `.vpc` file. Returns NULL invisibly
#'   if no features match the filter.
#'
#' @export
#'
#' @examples
#' # Example using the package's extdata folder
#' f <- system.file("extdata", package = "managelidar")
#' filter_spatial(f, c(547700, 5724010))
#'
filter_spatial <- function(path, extent, crs = NULL, out_file = NULL) {

  # Validate out_file if provided
  if (!is.null(out_file)) {
    if (tolower(fs::path_ext(out_file)) != "vpc") {
      stop("out_file must have .vpc extension")
    }
    if (fs::file_exists(out_file)) {
      stop("Output file already exists: ", out_file)
    }
  }

  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  if (nrow(vpc$features) == 0) {
    warning("No features in VPC to filter")
    return(invisible(NULL))
  }

  # Get target CRS from VPC
  target_epsg <- vpc$features$properties[[1]]$`proj:epsg`

  if (is.null(target_epsg)) {
    stop("VPC features missing proj:epsg")
  }

  # If crs is NULL and extent is numeric, use VPC's CRS
  if (is.null(crs) && is.numeric(extent)) {
    crs <- target_epsg
  }

  # Normalize extent to sf object
  extent_sf <- normalize_extent_to_sf(extent, crs)

  # Transform extent to VPC's CRS if needed
  if (sf::st_crs(extent_sf)$epsg != target_epsg) {
    extent_sf <- sf::st_transform(extent_sf, target_epsg)
  }

  # Create sf object from VPC features for intersection test
  vpc_bboxes <- lapply(seq_len(nrow(vpc$features)), function(i) {
    proj_bbox <- vpc$features$properties[[i]]$`proj:bbox`

    if (is.null(proj_bbox) || length(proj_bbox) < 4) {
      return(NULL)
    }

    # Create polygon from bbox
    sf::st_polygon(list(matrix(c(
      proj_bbox[1], proj_bbox[2],
      proj_bbox[3], proj_bbox[2],
      proj_bbox[3], proj_bbox[4],
      proj_bbox[1], proj_bbox[4],
      proj_bbox[1], proj_bbox[2]
    ), ncol = 2, byrow = TRUE)))
  })

  # Remove NULL entries
  valid_idx <- !vapply(vpc_bboxes, is.null, logical(1))
  vpc_bboxes <- vpc_bboxes[valid_idx]

  if (length(vpc_bboxes) == 0) {
    warning("No valid bounding boxes in VPC features")
    return(invisible(NULL))
  }

  vpc_geom <- sf::st_sfc(vpc_bboxes, crs = target_epsg)

  # Test intersection (sparse = TRUE returns list of indices)
  intersects_list <- sf::st_intersects(extent_sf, vpc_geom, sparse = TRUE)

  # Get unique VPC feature indices that intersect any extent feature
  keep_indices <- unique(unlist(intersects_list))

  # No intersections found
  if (length(keep_indices) == 0) {
    warning("No features intersect the specified extent")
    return(invisible(NULL))
  }

  # Create logical vector for all features
  keep <- rep(FALSE, nrow(vpc$features))
  keep[which(valid_idx)[keep_indices]] <- TRUE

  vpc$features <- vpc$features[keep, , drop = FALSE]

  # Return based on out_file parameter
  if (is.null(out_file)) {
    return(vpc)
  } else {
    yyjsonr::write_json_file(vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
}

#' Internal helper to normalize different extent formats to sf
#'
#' @param extent Spatial extent (numeric vector, sf, or sfc object)
#' @param crs CRS of the extent (required for numeric vectors)
#'
#' @return An sf object with geometry
#'
#' @keywords internal
normalize_extent_to_sf <- function(extent, crs = NULL) {
  # Already sf/sfc
  if (inherits(extent, "sf")) {
    return(extent)
  }

  if (inherits(extent, "sfc")) {
    return(sf::st_sf(geometry = extent))
  }

  # Numeric vector
  if (is.numeric(extent)) {
    if (length(extent) == 2) {
      # Single point
      geom <- sf::st_point(extent)
    } else if (length(extent) == 4) {
      # Bbox -> polygon
      geom <- sf::st_polygon(list(matrix(c(
        extent[1], extent[2],
        extent[3], extent[2],
        extent[3], extent[4],
        extent[1], extent[4],
        extent[1], extent[2]
      ), ncol = 2, byrow = TRUE)))
    } else {
      stop("Numeric extent must be length 2 (x, y) or 4 (xmin, ymin, xmax, ymax)")
    }

    if (is.null(crs)) {
      stop("Must provide 'crs' when extent is a numeric vector")
    }

    return(sf::st_sf(geometry = sf::st_sfc(geom, crs = crs)))
  }

  stop("Unsupported extent type. Use numeric vector or sf object.")
}
