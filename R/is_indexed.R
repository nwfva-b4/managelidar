#' Check whether LASfiles are spatially indexed
#'
#' `is_indexed()` whether LASfiles are spatially indexed (either via external `.lax` file or internally)
#'
#' The input may be a single file, a directory containing LASfiles, or a
#' Virtual Point Cloud (`.vpc`) referencing LAS/LAZ/COPC files. Internally,
#' file paths are resolved using `resolve_las_paths()`.
#'
#' @param path Character. Path(s) to a LAS/LAZ/COPC file, a directory containing
#'   such files, or a Virtual Point Cloud (`.vpc`).
#' @param full.names Logical. If `TRUE`, return full file paths; otherwise
#'   return base filenames only (default).
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{file}{Filename of the LASfile.}
#'   \item{is_indexed}{Logical indicating whether point cloud is spatially indexed}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' las_files |> is_indexed()
#'
is_indexed <- function(path, full.names = FALSE) {
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  indexed <- lasR:::is_indexed(files)

  # adjust filenames
  if (!full.names) files <- basename(files)

  data.frame(filename = files, indexed)
}
