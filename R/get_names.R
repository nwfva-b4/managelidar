#' Get LAS file names
#'
#' `get_names()` returns the filenames of all LAS-related point cloud files
#' (`.las`, `.laz`, `.copc`) found in a given input.
#'
#' The input may be a single file, a directory containing LAS files, or a
#' Virtual Point Cloud (`.vpc`) referencing LAS/LAZ/COPC files. Internally,
#' file paths are resolved using `resolve_las_paths()`.
#'
#' @param path Character. Path(s) to a LAS/LAZ/COPC file, a directory containing
#'   such files, or a Virtual Point Cloud (`.vpc`).
#' @param full.names Logical. If `TRUE`, return full file paths; otherwise
#'   return base filenames only (default).
#'
#' @return A character vector of filenames or file paths.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_names(f)
get_names <- function(path, full.names = FALSE) {

  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    stop("No LAS/LAZ/COPC files found.")
  }

  # adjust filenames
  if (!full.names) files <- basename(files)

  files
}
