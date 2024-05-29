
#' Get file names
#'
#' Simply list the names of all lasfiles (*.laz) in the folder.
#'
#' @param path A path to a directory which contains laz files
#'
#' @return A vector of filenames
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_names(f)
get_names <- function(path){
  f <- list.files(path, pattern = "*.laz$", full.names = FALSE)
  return(f)
}
