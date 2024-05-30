
#' Get the Version of laz files
#'
#' @param path A path to a laz file or a directory which contains laz files
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file and lasversion (Major.Minor)
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

    return(data.frame(file = file, lasversion = paste0(major, ".", minor)))

  }


  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_lasversion(path)))
  }
  else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_lasversion))))
  }


}
