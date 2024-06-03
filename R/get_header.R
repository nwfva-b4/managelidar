
#' Get Fileheader from las file
#'
#' Provides a simple wrapper to read the fileheader from LAS/LAZ files via lidR::readLASheader.
#'
#' @param file A path to a laz file
#'
#' @return LASheader
#' @export
#'
#' @examples
#' f <- system.file("extdata/3dm_32_547_5724_1_ni_20240327.laz", package="managelidar")
#' get_header(f)
get_header <- function(file){
  fileheader <- lidR::readLASheader(file)
  return(fileheader)
}
