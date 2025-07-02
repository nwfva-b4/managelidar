#' Get the approximate point and pulse density of LAS files
#'
#' `get_density()` calculates the approximate average point and pulse (first/last-return only) density of LAS files.
#'
#' For this function only the header from LAS files is read and density is calculated based on the bounding box of the data file and the number of points of first-returns. This does not take into account if parts of the bounding box are missing data, and hence this density does not reflect the density as it is calculates by e.g. `lidR`. However, it is much faster because it does not read the entire file and density should be approximately the same if the entire bounding box has point data.
#'
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#'
#' @return A data.frame with attributes `filename`, `npoints`, `npulses`, `area`, `pointdensity` and `pulsedensity`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_density(f)
#'
get_density <- function(path, full.names = FALSE){

  get_file_density <- function(file){

    fileheader <- lidR::readLASheader(file)

    minx <- fileheader$`Min X`
    miny <- fileheader$`Min Y`
    maxx <- fileheader$`Max X`
    maxy <- fileheader$`Max Y`

    points <- fileheader$`Number of point records`
    pulses <- fileheader$`Number of points by return`[1]
    bbox <- sf::st_bbox(c(xmin = minx, xmax = maxx, ymax = maxy, ymin = miny), crs = sf::st_crs(fileheader))
    area <- sf::st_area(sf::st_as_sfc(bbox))
    pointdensity <- points / area
    pulsedensity <- pulses / area



    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(filename = file, npoints = points, npulses = pulses, area, pointdensity, pulsedensity))

  }

  if (file.exists(path) && !dir.exists(path)) {

    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      return(as.data.frame(do.call(rbind, lapply(f, get_file_density))))
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      return(as.data.frame(get_file_density(path)))
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {

    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_density))))
  } else {
    stop("Path does not exist: ", path)
  }

}

