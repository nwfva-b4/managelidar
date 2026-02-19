#' Plot the spatial extent of LASfiles
#'
#' Visualizes the spatial extent of LAS/LAZ/COPC files on an interactive map.
#'
#' @param path Character. Path(s) to LAS/LAZ/COPC files, a directory, a VPC file,
#'   or a VPC object already loaded in R.
#' @param per_file Logical. If `TRUE` (default), plots extent per file. 
#'   If `FALSE`, plots combined extent as a single polygon.
#' @param full.names Logical. If `TRUE`, shows full file paths in labels; 
#'   otherwise shows base filenames (default). Only used when `per_file = TRUE`.
#' @param verbose Logical. If `TRUE` (default), prints extent information.
#'
#' @return An interactive `mapview` map displayed in the viewer.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' # Plot extent per file
#' las_files |> plot_extent()
#' 
#' # Plot combined extent
#' las_files |> plot_extent(per_file = FALSE)
#' 
plot_extent <- function(path, per_file = TRUE, full.names = FALSE, verbose = TRUE) {
  # Get extent as sf object
  ext <- get_spatial_extent(path, per_file = per_file, as_sf = TRUE, 
                           full.names = full.names, verbose = verbose)
  
  # Check if get_spatial_extent returned NULL
  if (is.null(ext)) {
    return(invisible(NULL))
  }
  
  # ------------------------------------------------------------------
  # Plot
  # ------------------------------------------------------------------
  mapview::mapviewOptions(basemaps = "OpenTopoMap")
  
  if (per_file) {
    # Plot with filename labels
    mapview::mapview(
      ext,
      alpha.regions = 0,
      label = "filename"
    )
  } else {
    # Plot combined extent without labels
    mapview::mapview(
      ext,
      alpha.regions = 0,
      label = FALSE
    )
  }
}