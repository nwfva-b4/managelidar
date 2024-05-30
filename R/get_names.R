
#' Get file names
#'
#' Simply get a vector of names of all lasfiles (*.laz) in the folder.
#'
#' @param path A path to a laz file or a directory which contains laz files
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A vector of filenames
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_names(f)
get_names <- function(path, full.names = FALSE){

  if (file.exists(path) && !dir.exists(path)) {
    if (full.names==FALSE) {
      file <- basename(path)
    }
    else {
      file <- path
    }
  } else {
    file <- list.files(path, pattern = "*.laz$", full.names = full.names)
  }

  return(file)
}
