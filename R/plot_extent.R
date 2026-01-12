#' Plot the spatial extent of LAS files
#'
#' `plot_extent()` visualizes the spatial extent of LAS/LAZ/COPC files on an
#' interactive map using bounding boxes derived from file headers or an
#' existing Virtual Point Cloud (VPC).
#'
#' @param path Character. Path(s) to LAS/LAZ/COPC files, a directory containing
#'   such files, or a Virtual Point Cloud (.vpc).
#'
#' @return An interactive `mapview` map displayed in the viewer.
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' plot_extent(f)
plot_extent <- function(path, full.names = FALSE) {
  # get extent
  ext <- get_extent(path, as_sf = TRUE, full.names = full.names)

  # ------------------------------------------------------------------
  # Plot
  # ------------------------------------------------------------------
  mapview::mapviewOptions(basemaps = "OpenTopoMap")

  mapview::mapview(
    ext,
    alpha.regions = 0,
    label = "filename"
  )
}
