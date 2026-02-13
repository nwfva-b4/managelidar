#' Get the spatial extent of LAS files
#'
#' `get_extent()` extracts the spatial extent (xmin, xmax, ymin, ymax) from LASfiles.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual Point Cloud (.vpc) referencing these files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths; otherwise base filenames (default).
#' @param as_sf Logical. If `TRUE`, returns an `sf` object with geometry.
#'
#' @return A `data.frame` or `sf` object with columns:
#' \describe{
#'   \item{filename}{Filename of the LAS file.}
#'   \item{xmin}{Minimum X coordinate.}
#'   \item{xmax}{Maximum X coordinate.}
#'   \item{ymin}{Minimum Y coordinate.}
#'   \item{ymax}{Maximum Y coordinate.}
#'   \item{geometry}{(optional) Polygon geometry if `as_sf = TRUE`.}
#' }
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_extent(f)
get_extent <- function(path, as_sf = FALSE, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Resolve LAS files and build VPC if not provided
  # ------------------------------------------------------------------
  vpc <- resolve_vpc(path)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
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

  # optionally return as sf
  if (as_sf) {
    geometries <- lapply(vpc$features$geometry, function(geom) {
      sf::st_polygon(geom$coordinates)
    })

    geom_column <- sf::st_sfc(geometries, crs = 4326)

    # Create sf object
    ext <- sf::st_sf(ext, geometry = geom_column) |>
      sf::st_zm()
  }

  # adjust filenames
  if (!full.names) ext$filename <- basename(ext$filename)

  ext
}
