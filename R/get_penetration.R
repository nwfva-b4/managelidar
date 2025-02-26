#' Get the pulse penetration ratio of lasfiles
#'
#' `get_penetration()` calculates the approximate pulse penetration ratio of lasfiles.
#'
#' For this function only the header from lasfiles is read. It calculates the ratio of pulses which have a single return only, which have two returns, three returns, four returns, five returns, six returns and for convenience multiple returns (two or more). Beware that this does not have to be exact especially for small files since pulses can be split at borders.
#'
#'
#' @param path A path to a laz file or a directory which contains laz files
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file, single, two, three, four, five, six, multiple
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

    return(data.frame(file = file, single = round(singleton, 3), two = round(doubleton, 3), three = round(triple, 3), four = round(quadruple, 3), five = round(quintuple, 3), six = round(sextuple, 3), multiple = round(multiton, 3)))

  }

  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_penetration(path)))
  }
  else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_penetration))))
  }
}
