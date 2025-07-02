
#' Get the Version of LAS files
#'
#' @param path A path to a LAS file or a directory which contains LAS files
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#'
#' @return A data.frame with attributes `filename` and `lasversion` (Major.Minor)
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_lasversion(f)
get_lasversion <- function(path, full.names = FALSE){

  get_file_lasversion <- function(file){
    fileheader <- lidR::readLASheader(file)

    major = fileheader@PHB$`Version Major`
    minor = fileheader@PHB$`Version Minor`

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(filename = file, lasversion = paste0(major, ".", minor)))

  }


  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_lasversion(path)))
  }
  else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_lasversion))))
  }


}
