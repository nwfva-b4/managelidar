#' Get the spatial extent of LASfiles
#'
#' `get_spatial_extent()` extracts the spatial extent (xmin, xmax, ymin, ymax) from LASfiles.
#' Can return extent per file or the combined extent of all files.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual Point Cloud (.vpc) referencing these files.
#' @param per_file Logical. If `TRUE` (default), returns extent per file. If `FALSE`, returns combined extent of all files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths; otherwise base filenames (default). 
#'   Only used when `per_file = TRUE`.
#' @param as_sf Logical. If `TRUE`, returns an `sf` object with geometry. If `FALSE` (default), returns a data.frame.
#' @param verbose Logical. If `TRUE` (default), prints extent information.
#'
#' @return When `per_file = TRUE`: A `data.frame` or `sf` object with columns:
#' \describe{
#'   \item{filename}{Filename of the LASfile.}
#'   \item{xmin}{Minimum X coordinate.}
#'   \item{xmax}{Maximum X coordinate.}
#'   \item{ymin}{Minimum Y coordinate.}
#'   \item{ymax}{Maximum Y coordinate.}
#'   \item{geometry}{(optional) Polygon geometry if `as_sf = TRUE`.}
#' }
#' When `per_file = FALSE`: A single-row data.frame or sf object with the combined extent.
#'
#' @export
#'
#' @seealso \code{\link{get_temporal_extent}}, \code{\link{filter_spatial}}
#' 
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#' las_files |> get_spatial_extent()
#'
get_spatial_extent <- function(path, per_file = TRUE, full.names = FALSE, as_sf = FALSE, verbose = TRUE) {
  # ------------------------------------------------------------------
  # Resolve LASfiles and build VPC if not provided
  # ------------------------------------------------------------------
  vpc <- resolve_vpc(path, out_file = NULL)
  
  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }
  
  n_files <- nrow(vpc$features)
  
  if (n_files == 0) {
    warning("No features in VPC")
    return(invisible(NULL))
  }
  
  # ------------------------------------------------------------------
  # Read bbox info from VPC
  # ------------------------------------------------------------------
  ext <- data.frame(
    filename = sapply(vpc$features$assets, function(x) x$data$href),
    xmin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[1]),
    ymin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[2]),
    xmax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[3]),
    ymax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[4]),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  
  # Get CRS from first feature
  crs_epsg <- vpc$features$properties[[1]]$`proj:epsg`
  
  # Calculate overall extent
  overall_xmin <- min(ext$xmin)
  overall_ymin <- min(ext$ymin)
  overall_xmax <- max(ext$xmax)
  overall_ymax <- max(ext$ymax)
  
  # Print information
  if (verbose) {
    message("Get spatial extent")
    message(sprintf("  \u25BC %d LASfiles", n_files))
    if (!is.null(crs_epsg)) {
      message(sprintf("  Overall extent: %.2f, %.2f, %.2f, %.2f  (xmin, ymin, xmax, ymax; EPSG:%d)", 
                      overall_xmin, overall_ymin, overall_xmax, overall_ymax, crs_epsg))
    } else {
      message(sprintf("  Overall extent: %.2f, %.2f, %.2f, %.2f  (xmin, ymin, xmax, ymax)", 
                      overall_xmin, overall_ymin, overall_xmax, overall_ymax))
    }
  }
  
  # If per_file = FALSE, compute combined extent
  if (!per_file) {
    combined_ext <- data.frame(
      xmin = overall_xmin,
      ymin = overall_ymin,
      xmax = overall_xmax,
      ymax = overall_ymax,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
    
    # Optionally return as sf
    if (as_sf) {
      # Create polygon from bbox
      geom <- sf::st_polygon(list(matrix(c(
        combined_ext$xmin, combined_ext$ymin,
        combined_ext$xmax, combined_ext$ymin,
        combined_ext$xmax, combined_ext$ymax,
        combined_ext$xmin, combined_ext$ymax,
        combined_ext$xmin, combined_ext$ymin
      ), ncol = 2, byrow = TRUE)))
      
      geom_column <- sf::st_sfc(geom, crs = crs_epsg)
      combined_ext <- sf::st_sf(combined_ext, geometry = geom_column)
    }
    
    return(combined_ext)
  }
  
  # Optionally return as sf (per file mode)
  if (as_sf) {
    geometries <- lapply(vpc$features$geometry, function(geom) {
      sf::st_polygon(geom$coordinates)
    })
    geom_column <- sf::st_sfc(geometries, crs = 4326)
    # Create sf object
    ext <- sf::st_sf(ext, geometry = geom_column) |>
      sf::st_zm()
  }
  
  # Adjust filenames
  if (!full.names) {
    ext$filename <- basename(ext$filename)
  }
  
  ext
}