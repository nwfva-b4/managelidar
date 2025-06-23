
#' Get the Coordinate Reference System of LAS files
#'
#' @param path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe returning `filename` and `crs` (EPSG)
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
