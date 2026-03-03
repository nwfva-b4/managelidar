#' Get the extrabytes attributes stored in LASfiles
#'
#' `get_extrabytes_attributes()` extracts the names of extrabytes attributes
#' stored in LASfiles.
#'
#' @param path Character. Path(s) to LAS/LAZ/COPC files, a directory containing
#'   such files, or a Virtual Point Cloud (.vpc) referencing these files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths;
#'   otherwise base filenames (default).
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{filename}{Filename of the LASfile.}
#'   \item{extrabytes_attributes}{list of attribute names}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' folder |> get_extrabytes_attributes()
#'
get_extrabytes_attributes <- function(path, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Read headers (single I/O layer)
  # ------------------------------------------------------------------
  headers <- get_header(path, full.names = full.names)

  # ------------------------------------------------------------------
  # Extract LAS version
  # ------------------------------------------------------------------
  df <- dplyr::bind_rows(lapply(seq_along(headers), function(i) {
    hdr <- headers[[i]]

    tibble::tibble(
      filename = names(headers)[i],
      extrabytes_attributes = list(names(hdr@VLR$Extra_Bytes$`Extra Bytes Description`))
    )
  }))

  df
}
