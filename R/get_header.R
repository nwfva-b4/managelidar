#' Retrieve LAS file headers (metadata)
#'
#' `get_header()` reads the metadata included in the headers of LAS/LAZ/COPC files
#' without loading the full point cloud. It works on single files, directories,
#' or Virtual Point Cloud (.vpc) files referencing LAS files.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LAS files,
#'   or a Virtual Point Cloud (.vpc) file.
#' @param full.names Logical. If `TRUE`, the returned list is named with full file paths;
#'   if `FALSE` (default), the list is named with base filenames only.
#'
#' @return A named list of `LASheader` S4 objects, one per file.
#'   Use `names()` to see the file names or paths.
#'
#' @details
#' The function wraps `lidR::readLASheader()` and allows quick access to metadata such as
#' number of points, number of returns, point format, and coordinate system,
#' without loading the point cloud into memory.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_header(f)
get_header <- function(path, full.names = FALSE) {
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  headers <- map_las(files, lidR::readLASheader)

  names(headers) <- if (full.names) files else basename(files)

  headers
}
