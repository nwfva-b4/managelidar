#' Get the spatial extent of laz files
#'
#' `get_extent` uses min and max values of spatial extent defined in the header of lasfiles.
#'
#' @param path Either a path to a directory which contains laz files or
#' the path to a Virtual Point Cloud (.vpc) created with lasR package.
#'
#' @return A dataframe with file, minx, miny, maxx, maxy
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_extent(f)
get_extent <- function(path){

  get_file_extent <- function(file){
    fileheader <- lidR::readLASheader(file)

    minx = fileheader$`Min X`
    miny = fileheader$`Min Y`
    maxx = fileheader$`Max X`
    maxy = fileheader$`Max Y`

    return(data.frame(path = file, minx, miny, maxx, maxy))

  }

  f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
  return(as.data.frame(do.call(rbind, lapply(f, get_file_extent))))
}
