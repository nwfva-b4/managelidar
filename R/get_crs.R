#' Get the Coordinate Reference System (CRS) of LASfiles
#'
#' `get_crs()` efficiently extracts and returns the coordinate reference system (EPSG code) of LASfiles.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LASfiles,
#'   or a Virtual Point Cloud (.vpc) referencing LASfiles.
#' @param full.names Logical. If `TRUE`, the returned filenames will be full paths;
#'   if `FALSE` (default), only base filenames are used.
#'
#' @return A `data.frame` with two columns:
#' \describe{
#'   \item{filename}{The filename or full path of each LASfile.}
#'   \item{crs}{The EPSG code of the file's coordinate reference system.}
#' }
#'
#' @details
#' This function efficiently reads the Coordinate Reference System of LASfiles from VPC. It is suitable
#' for quickly inspecting the CRS of multiple LAS/LAZ/COPC files.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' las_files |> get_crs()
#'
get_crs <- function(path, full.names = FALSE) {
  files <- resolve_las_paths(path)
  if (length(files) == 0) {
    return(invisible(NULL))
  }

  res <- data.frame(
    filename = files,
    crs = sapply(files, function(f) {
      hdr <- lidR::readLASheader(f)
      epsg <- lidR::epsg(hdr)
      if (is_valid_crs(epsg)) epsg else NA_integer_
    }),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  if (!full.names) res$filename <- basename(res$filename)
  res
}
