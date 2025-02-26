#' Get the spatial extent of laz files
#'
#' `get_extent` uses min and max values of spatial extent defined in the header of lasfiles.
#'
#' @param path Either a path to a directory which contains laz files or
#' the path to a Virtual Point Cloud (.vpc) created with lasR package.
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file, minx, miny, minz, maxx, maxy, maxz
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_extent(f)
get_extent <- function(path, full.names = FALSE){

  get_file_extent <- function(file){
    fileheader <- lidR::readLASheader(file)

    minx = fileheader$`Min X`
    miny = fileheader$`Min Y`
    minz = fileheader$`Min Z`
    maxx = fileheader$`Max X`
    maxy = fileheader$`Max Y`
    maxz = fileheader$`Max Z`

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(file = file, minx, miny, minz, maxx, maxy, maxz))

  }

  f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
  return(as.data.frame(do.call(rbind, lapply(f, get_file_extent))))
}
