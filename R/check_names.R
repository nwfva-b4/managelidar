
#' Check file names
#'
#' Checks the file names according to our own standard.
#' File names should be in the following schema:
#' "prefix_UTMzone_minx_miny_tilesize_region_acquisitiondate.laz"
#'
#' (e.g. "3dm_32_547_5724_1_ni_20240327.laz")
#'
#' @param path A path to a laz file or a directory which contains laz files
#' @param prefix 3 letter character. Naming prefix (defaults to "3dm")
#' @param zone 2 digits integer. UTM zone (defaults to 32)
#' @param region 2 letter character. Region abbreviation (defaults to "ni")
#' @param date YYYYMMDD. (optional) acquisition date
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with name_is, name_should, correct
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' check_names(f)
check_names <- function(path, prefix = "3dm", zone = 32, region = "ni", date = NULL, full.names = FALSE){

  check_file_names <- function(file){

    if(is.null(date)){
      date = substr(basename(file), 22, 29)
    }

    fileheader <- lidR::readLASheader(file)
    minx = floor(fileheader$`Min X` / 1000)
    miny = floor(fileheader$`Min Y` / 1000)
    maxx = ceiling(fileheader$`Max X` / 1000)
    maxy = ceiling(fileheader$`Max Y` / 1000)

    if((maxx - minx) == (maxy - miny)){
      tilesize = maxx - minx
    } else
      {print("tiles are not quadratic")}



    name_should = paste0(prefix, "_", zone, "_", minx, "_", miny, "_", tilesize, "_", region, "_", date, ".laz")

    if(basename(file) != name_should){
      correct = FALSE
    }
    else{
      correct = TRUE
    }

    if (full.names == FALSE){
      file <- basename(file)
    }
    if (full.names == TRUE){
      name_should <- file.path(dirname(file), name_should)
    }


    return(data.frame(name_is = file,
                      name_should = name_should,
                      correct_naming = correct))

  }

  if (file.exists(path) && !dir.exists(path)) {

    check_file_names(path)
  }
  else {
    files <- list.files(path, pattern = "*.laz$", full.names = T)
    return(as.data.frame(do.call(rbind, lapply(files, check_file_names))))
  }

}
