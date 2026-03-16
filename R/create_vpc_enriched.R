#' Create enriched Virtual Point Cloud with outlines and summary metadata
#'
#' Creates an enriched VPC from LAS/LAZ/COPC files with detailed outline geometries
#' and summary statistics.
#'
#' This function is typically used after \code{\link{raw_to_processed}} to create
#' a collection-level VPC with enhanced metadata.
#'
#' @param path Character. Path to LAS/LAZ/COPC file(s), directory, VPC file(s),
#'   or VPC object.
#' @param outlines Character or logical. Directory containing outline GeoJSON files.
#'   If NULL (default), looks for an 'outlines' directory adjacent to the input files.
#'   If FALSE, geometry will not be updated from outlines.
#' @param metadata Character or logical. Directory containing summary JSON files.
#'   If NULL (default), looks for a 'metadata' directory adjacent to the input files.
#'   If FALSE, metadata properties will not be added.
#' @param out_file Character. Output VPC file path. If NULL (default), returns
#'   the enriched VPC as an R object.
#' @param verbose Logical. Print progress messages (default: TRUE).
#'
#' @return If \code{out_file} is NULL, returns the enriched VPC as a list.
#'   If \code{out_file} is provided, saves to file and returns the file path.
#'
#' @details
#' This function enriches VPC features with:
#' \itemize{
#'   \item Detailed outline geometries (WGS84 polygons instead of bounding boxes)
#'   \item Point and pulse density statistics
#'   \item Per-dimension statistics (Z, Intensity, GpsTime)
#'   \item Classification and return number distributions
#' }
#'
#' **Typical workflow:**
#' \enumerate{
#'   \item Run \code{\link{raw_to_processed}} to create processed point clouds with
#'         outlines and metadata in standardized directories
#'   \item Run \code{create_vpc_enriched} to create a collection VPC with enhanced
#'         metadata from those directories
#' }
#'
#' **Auto-detection:** When \code{outlines} or \code{metadata} are NULL, the function
#' looks for directories named 'outlines' and 'metadata' in the parent directory
#' of the input files (as created by \code{\link{raw_to_processed}}).
#'
#' **Selective enrichment:** Set \code{outlines = FALSE} to skip geometry enrichment,
#' or \code{metadata = FALSE} to skip metadata enrichment.
#'
#' The enriched VPC follows the STAC pointcloud extension specification with
#' additional custom properties for point and pulse density.
#'
#' @export
#'
#' @examples
#' # Typical workflow after raw_to_processed
#' folder <- system.file("extdata", package = "managelidar")
#' vpc_enriched <- folder |>
#'   raw_to_processed() |>
#'   create_vpc_enriched()
create_vpc_enriched <- function(path, outlines = NULL, metadata = NULL, out_file = NULL, verbose = TRUE) {
  # Create/resolve VPC
  vpc <- resolve_vpc(path, out_file = NULL)

  if (is.null(vpc) || length(vpc$features) == 0) {
    warning("No valid VPC features found")
    return(invisible(NULL))
  }

  n_features <- nrow(vpc$features)

  if (verbose) {
    message(sprintf(
      "Create enriched VPC with %d feature%s",
      n_features, if (n_features != 1) "s" else ""
    ))
  }

  # Auto-detect directories if NULL
  if (is.null(outlines) || is.null(metadata)) {
    # Get parent directory from first LAS file
    first_las <- vpc$features$assets[[1]]$data$href
    parent_dir <- fs::path_dir(fs::path_dir(first_las))

    if (is.null(outlines)) {
      candidate_outline <- fs::path(parent_dir, "outlines")
      if (fs::dir_exists(candidate_outline)) {
        outlines <- candidate_outline
        if (verbose) message(sprintf("Auto-detected outline directory: %s", outlines))
      } else {
        outlines <- FALSE
        if (verbose) message("No outline directory found - skipping geometry enrichment")
      }
    }

    if (is.null(metadata)) {
      candidate_metadata <- fs::path(parent_dir, "metadata")
      if (fs::dir_exists(candidate_metadata)) {
        metadata <- candidate_metadata
        if (verbose) message(sprintf("Auto-detected metadata directory: %s", metadata))
      } else {
        metadata <- FALSE
        if (verbose) message("No metadata directory found - skipping metadata enrichment")
      }
    }
  }

  # Check what enrichment to perform
  enrich_geometry <- !isFALSE(outlines)
  enrich_metadata <- !isFALSE(metadata)

  if (!enrich_geometry && !enrich_metadata) {
    warning("Both outlines and metadata are FALSE - nothing to enrich")
    return(vpc)
  }

  enriched_count <- 0

  # Process each feature
  for (i in seq_len(n_features)) {
    feature_id <- vpc$features$id[i]

    # Variables to store
    outline_sf <- NULL
    outline_area <- NULL
    metadata_content <- NULL

    # Read outline if requested
    if (enrich_geometry) {
      outline_file <- fs::path(outlines, fs::path_ext_set(feature_id, ".geojson"))

      if (fs::file_exists(outline_file)) {
        outline_sf <- sf::st_read(outline_file, quiet = TRUE)
        outline_area <- as.numeric(sf::st_area(outline_sf))
      } else {
        if (verbose) message(sprintf("  Skip %s - outline not found", feature_id))
      }
    }

    # Read metadata if requested
    if (enrich_metadata) {
      metadata_file <- fs::path(metadata, fs::path_ext_set(feature_id, ".json"))

      if (fs::file_exists(metadata_file)) {
        metadata_content <- yyjsonr::read_json_file(metadata_file)
      } else {
        if (verbose) message(sprintf("  Skip %s - metadata not found", feature_id))
      }
    }

    # Skip if nothing to add
    if (is.null(outline_sf) && is.null(metadata_content)) {
      next
    }

    # Update geometry if outline exists
    if (!is.null(outline_sf)) {
      # Transform to WGS84 for geometry
      outline_wgs84 <- sf::st_transform(outline_sf, 4326)
      geom_obj <- sf::st_geometry(outline_wgs84)[[1]]

      # Convert to GeoJSON coordinates
      if (inherits(geom_obj, "MULTIPOLYGON")) {
        coords <- lapply(geom_obj, function(poly) {
          lapply(poly, function(ring) {
            lapply(seq_len(nrow(ring)), function(j) round(ring[j, 1:2], 7))
          })
        })
        vpc$features$geometry[[i]] <- list(type = "MultiPolygon", coordinates = coords)
      } else {
        coords <- lapply(geom_obj, function(ring) {
          lapply(seq_len(nrow(ring)), function(j) round(ring[j, 1:2], 7))
        })
        vpc$features$geometry[[i]] <- list(type = "Polygon", coordinates = coords)
      }
    }

    # Add metadata if exists
    if (!is.null(metadata_content)) {
      new_props <- list()

      # Point density
      if (!is.null(outline_area)) {
        new_props$pointdensity <- round(metadata_content$npoints / outline_area, 2)
      }

      # Pulse density (first returns per square meter)
      if (!is.null(outline_area)) {
        first_returns <- metadata_content$npoints_per_return[["1"]]
        new_props$pulsedensity <- round(first_returns / outline_area, 2)
      }

      # Statistics array
      stats <- list()

      # Handle metrics as data.frame or list
      if (is.data.frame(metadata_content$metrics)) {
        metrics <- metadata_content$metrics[1, ]
      } else {
        metrics <- metadata_content$metrics[[1]]
      }

      # Z statistics
      stats[[length(stats) + 1]] <- list(
        name = "Z",
        minimum = round(metrics$z_min, 3),
        maximum = round(metrics$z_max, 3),
        mean = round(metrics$z_median, 3)
      )

      # Intensity statistics
      stats[[length(stats) + 1]] <- list(
        name = "Intensity",
        minimum = as.integer(metrics$i_min),
        maximum = as.integer(metrics$i_max),
        mean = as.integer(round(metrics$i_mean)),
        median = as.integer(metrics$i_median),
        stddev = round(metrics$i_sd, 2)
      )

      # GpsTime statistics
      stats[[length(stats) + 1]] <- list(
        name = "GpsTime",
        minimum = round(metrics$t_min, 2),
        maximum = round(metrics$t_max, 2),
        median = round(metrics$t_median, 2)
      )

      # Classification statistics
      class_counts <- metadata_content$npoints_per_class
      class_nums <- as.integer(names(class_counts))

      stats[[length(stats) + 1]] <- list(
        name = "Classification",
        minimum = min(class_nums),
        maximum = max(class_nums),
        `class-count` = as.list(class_counts)
      )

      # Return number statistics
      return_counts <- metadata_content$npoints_per_return
      return_nums <- as.integer(names(return_counts))

      stats[[length(stats) + 1]] <- list(
        name = "ReturnNumber",
        minimum = min(return_nums),
        maximum = max(return_nums),
        `class-count` = as.list(return_counts)
      )

      new_props$`pc:statistics` <- stats

      # Merge with existing properties
      current_props <- vpc$features$properties[[i]]
      vpc$features$properties[[i]] <- c(current_props, new_props)
    }

    enriched_count <- enriched_count + 1

    if (verbose) {
      parts <- c(
        if (!is.null(outline_sf)) "geometry",
        if (!is.null(metadata_content)) "metadata"
      )
      message(sprintf("  \u2713 %s (%s)", feature_id, paste(parts, collapse = " + ")))
    }
  }

  if (verbose) {
    message(sprintf("\nEnriched: %d / %d", enriched_count, n_features))
  }

  # Return or save
  if (is.null(out_file)) {
    return(vpc)
  } else {
    yyjsonr::write_json_file(vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    if (verbose) message(sprintf("Saved to: %s", out_file))
    return(out_file)
  }
}
