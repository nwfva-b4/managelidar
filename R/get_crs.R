#' Get the Coordinate Reference System (CRS) of LAS files
#'
#' `get_crs()` extracts the coordinate reference system (EPSG code) from the
#' headers of LAS/LAZ/COPC files. It works on individual files, directories
#' containing LAS files, or Virtual Point Cloud (.vpc) files referencing LAS files.
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
#' This function reads only the LAS file headers using \code{get_header()},
#' which avoids loading the full point cloud into memory. It is suitable
#' for quickly inspecting the CRS of multiple LAS/LAZ/COPC files.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_crs(f)
#'
get_crs <- function(path, full.names = FALSE){

  header <- get_header(path, full.names = full.names)

  do.call(rbind, lapply(seq_along(header), function(i) {
    hdr <- header[[i]]
    data.frame(
      filename = names(header)[i],
      crs = lidR::epsg(hdr),
      stringsAsFactors = FALSE
    )
  }))

}
