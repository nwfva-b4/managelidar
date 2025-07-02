#' Get the pulse penetration ratio of LAS files
#'
#' `get_penetration()` calculates the approximate pulse penetration ratio of LAS files.
#'
#' For this function only the header from lasfiles is read. It calculates the ratio of pulses which have a single return only, which have two returns, three returns, four returns, five returns, six returns and for convenience multiple returns (two or more). Beware that this does not have to be exact especially for small files since pulses can be split at borders.
#'
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#'
#' @return A data.frame with attributes `filename`, `single`, `two`, `three`, `four`, `five`, `six` and `multiple`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package="managelidar")
#' get_penetration(f)
get_penetration <- function(path, full.names = FALSE){

  get_file_penetration <- function(file){
    fileheader <- lidR::readLASheader(file)

    pulses = fileheader$`Number of points by return`[1]

    # single return ratio
    singleton = (fileheader$`Number of points by return`[[1]] - fileheader$`Number of points by return`[[2]]) / pulses
    # two return ratio
    doubleton = (fileheader$`Number of points by return`[[2]] - fileheader$`Number of points by return`[[3]]) / pulses
    # three return ratio
    triple = (fileheader$`Number of points by return`[[3]] - fileheader$`Number of points by return`[[4]]) / pulses
    # four return ratio
    quadruple = (fileheader$`Number of points by return`[[4]] - fileheader$`Number of points by return`[[5]]) / pulses
    # five return ratio
    quintuple = (fileheader$`Number of points by return`[[5]] - fileheader$`Number of points by return`[[6]]) / pulses
    # six return ratio
    sextuple = (fileheader$`Number of points by return`[[6]] - fileheader$`Number of points by return`[[7]]) / pulses
    # multi return ratio
    multiton = fileheader$`Number of points by return`[[2]] / pulses

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(data.frame(filename = file, single = round(singleton, 3), two = round(doubleton, 3), three = round(triple, 3), four = round(quadruple, 3), five = round(quintuple, 3), six = round(sextuple, 3), multiple = round(multiton, 3)))

  }

if (file.exists(path) && !dir.exists(path)) {

    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      return(as.data.frame(do.call(rbind, lapply(f, get_file_penetration))))
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      return(as.data.frame(get_file_penetration(path)))
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {

    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_penetration))))
  } else {
    stop("Path does not exist: ", path)
  }
}
