#' Get file names
#'
#' Simply get a vector of names of all LAS files (*.las, *.laz, *.laz.copc) in the folder.
#'
#' @param path A path to a LAS file, VPC file, or a directory which contains LAS files
#'
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#'
#' @return A vector of filenames
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_names(f)
get_names <- function(path, full.names = FALSE) {
  # Single file input

  if (file.exists(path) && !dir.exists(path)) {
    # Single file input
    if (tools::file_ext(path) == "vpc") {
      t <- yyjsonr::read_json_file(path)
      files <- sapply(t$features$assets, function(x) x$data$href)
      if (full.names == FALSE) {
        file <- basename(files)
      } else {
        file <- files
      }
    } else if (tools::file_ext(path) %in% c("las", "laz", "copc")) {
      if (full.names == FALSE) {
        file <- basename(path)
      } else {
        file <- path
      }
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .laz.copc, .vpc")
    }
  } else {
    # Pattern to match .las, .laz, and .laz.copc files
    file <- list.files(path, pattern = "\\.(las|laz(\\.copc)?)$", full.names = full.names)
  }

  return(file)
}
