
#' Get the Coordinate Reference System of LAS files
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#'
#' @return A data.frame with attributes `filename` and `crs` (EPSG)
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_crs(f)
#'
get_crs <- function(path, full.names = FALSE){

  header <- get_header(path, full.names = full.names)
  df <- do.call(rbind, lapply(header, function(x) data.frame(filename = x$filename, crs = lidR::epsg(x$header))))
  return(df)

}
