
#' Get the Coordinate Reference system of laz files
#'
#' @param path A path to a laz file or a directory which contains laz files
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file and crs (EPSG)
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_crs(f)
get_crs <- function(path, full.names = FALSE){

  get_file_crs <- function(file){
    fileheader <- lidR::readLASheader(file)

    crs = lidR::epsg(fileheader)

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(file = file, crs))

  }

  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_crs(path)))
  }
  else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_crs))))
  }
}
