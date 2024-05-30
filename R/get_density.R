#' Get the approximate pulse density of lasfiles
#'
#' `get_density()` calculates the approximate average pulse density (first/last-return only) of lasfiles.
#'
#' For this function only the header from lasfiles is read and density is calculated from the bounding box of the data file and the number of first-returns. This does not take into account if parts of the bounding box is missing data, and hence this density does not reflect the density as it is calculates by e.g. `lidR`. However, it is much faster because it does not read the entire file and density should be approximately the same if the entire bounding box has point data.
#'
#'
#' @param path A path to a laz file or a directory which contains laz files
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file, pulses, area, density
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_density(f)
get_density <- function(path, full.names = FALSE){

  get_file_density <- function(file){
    fileheader <- lidR::readLASheader(file)

    minx = fileheader$`Min X`
    miny = fileheader$`Min Y`
    maxx = fileheader$`Max X`
    maxy = fileheader$`Max Y`

    firstreturns = fileheader$`Number of points by return`[1]
    bbox = sf::st_bbox(c(xmin = minx, xmax = maxx, ymax = maxy, ymin = miny), crs = sf::st_crs(fileheader))
    area = sf::st_area(sf::st_as_sfc(bbox))
    density =  firstreturns / area

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(file = file, pulses = firstreturns, area = area, density = density))

  }

  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_density(path)))
  }
  else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_density))))
  }
}
