#' Get the Coordinate Reference System (CRS) of LAS files
#'
#' `get_crs()` efficiently extracts and returns the coordinate reference system (EPSG code) of LAS files.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LAS files,
#'   or a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param full.names Logical. If `TRUE`, the returned filenames will be full paths;
#'   if `FALSE` (default), only base filenames are used.
#'
#' @return A `data.frame` with two columns:
#' \describe{
#'   \item{filename}{The filename or full path of each LAS file.}
#'   \item{crs}{The EPSG code of the file's coordinate reference system.}
#' }
#'
#' @details
#' This function efficiently reads the Coordinate Reference System of LAS files from VPC. It is suitable
#' for quickly inspecting the CRS of multiple LAS/LAZ/COPC files.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_crs(f)
#'
get_crs <- function(path, full.names = FALSE) {
  vpc <- resolve_vpc(path)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  res <- data.frame(
    filename = sapply(vpc$features$assets, function(x) x$data$href),
    crs = sapply(vpc$features$properties, function(x) x$`proj:epsg`)
  )

  # Adjust filenames
  if (!full.names) {
    res$filename <- basename(res$filename)
  }

  res
}
