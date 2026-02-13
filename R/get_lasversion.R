#' Get the LAS version of point cloud files
#'
#' `get_lasversion()` extracts the LAS specification version (Major.Minor)
#' from the file headers of LAS/LAZ/COPC files.
#'
#' @param path Character. Path(s) to LAS/LAZ/COPC files, a directory containing
#'   such files, or a Virtual Point Cloud (.vpc) referencing these files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths;
#'   otherwise base filenames (default).
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{filename}{Filename of the LAS file.}
#'   \item{lasversion}{LAS version in `Major.Minor` format.}
#' }
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_lasversion(f)
get_lasversion <- function(path, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Read headers (single I/O layer)
  # ------------------------------------------------------------------
  headers <- get_header(path, full.names = full.names)

  # ------------------------------------------------------------------
  # Extract LAS version
  # ------------------------------------------------------------------
  df <- do.call(rbind, lapply(seq_along(headers), function(i) {
    hdr <- headers[[i]]

    data.frame(
      filename = names(headers)[i],
      lasversion = paste0(
        hdr@PHB$`Version Major`,
        ".",
        hdr@PHB$`Version Minor`
      ),
      stringsAsFactors = FALSE
    )
  }))

  df
}
