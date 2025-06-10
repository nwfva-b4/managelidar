#' Get the approximate pulse density of lasfiles
#'
#' `get_density()` calculates the approximate average point and pulse (first/last-return only) density of lasfiles.
#'
#' For this function only the header from lasfiles is read and density is calculated from the bounding box of the data file and the number of points or first-returns. This does not take into account if parts of the bounding box is missing data, and hence this density does not reflect the density as it is calculates by e.g. `lidR`. However, it is much faster because it does not read the entire file and density should be approximately the same if the entire bounding box has point data.
#'
#'
#' @param path The path to a file (las/laz/copc), to a directory which contains these files, or to a VPC file referencing these files.
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file, points, pulses, area, pointdensity, pulsedensity
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
    
    points = fileheader$`Number of point records`
    pulses = fileheader$`Number of points by return`[1]
    bbox = sf::st_bbox(c(xmin = minx, xmax = maxx, ymax = maxy, ymin = miny), crs = sf::st_crs(fileheader))
    area = sf::st_area(sf::st_as_sfc(bbox))
    pointdensity = points / area
    pulsedensity =  pulses / area
    
    if (full.names == FALSE){
      file <- basename(file)
    }
    
    return(data.frame(file = file, points = points, pulses = pulses, area = area, pointdensity = pointdensity, pulsedensity = pulsedensity))
    
  }
  
  if (file.exists(path) && !dir.exists(path)) {
    # Single file input
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      return(as.data.frame(do.call(rbind, lapply(f, get_file_density))))
    } else if (tools::file_ext(path) %in% c("las", "laz", "copc")) {
      return(as.data.frame(get_file_density(path)))
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .laz.copc, .vpc")
    }
  } else if (dir.exists(path)) {
    
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_density))))
  }
}