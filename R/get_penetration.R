#' Compute pulse penetration ratios from LAS headers
#'
#' `get_penetration()` computes approximate pulse penetration ratios for
#' LAS/LAZ/COPC files using information stored in the LAS file header.
#' Only header data are read; point data are not loaded.
#'
#' The function estimates the proportion of pulses that resulted in
#' exactly one return, two returns, three returns, up to six returns,
#' as well as the proportion of pulses with multiple returns (two or more).
#'
#' @param path Character vector specifying one or more paths to:
#'   \itemize{
#'     \item LAS/LAZ/COPC files
#'     \item Directories containing LAS/LAZ/COPC files (non-recursive)
#'     \item Virtual Point Cloud files (`.vpc`) referencing LAS files
#'   }
#'
#' @param full.names Logical. If `TRUE`, return full file paths in the
#'   `filename` column. If `FALSE` (default), only the base file names
#'   are returned.
#'
#' @return
#' A `data.frame` with one row per input file and the following columns:
#' \describe{
#'   \item{filename}{File name or full path of the LAS file}
#'   \item{single}{Proportion of pulses with exactly one return}
#'   \item{two}{Proportion of pulses with exactly two returns}
#'   \item{three}{Proportion of pulses with exactly three returns}
#'   \item{four}{Proportion of pulses with exactly four returns}
#'   \item{five}{Proportion of pulses with exactly five returns}
#'   \item{six}{Proportion of pulses with exactly six returns}
#'   \item{multiple}{Proportion of pulses with two or more returns}
#' }
#'
#' @details
#' Pulse penetration ratios are derived from the
#' \dQuote{Number of points by return} field in the LAS header.
#' Because only header information is used, results are approximate.
#'
#' For small files or spatially clipped tiles, pulses may be split at
#' tile boundaries, which can lead to biased penetration ratios.
#' Consequently, values should be interpreted as indicative rather than
#' exact.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_penetration(f)

get_penetration <- function(path, full.names = FALSE){

  get_penetration_per_file <- function(file){
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

    # adjust filenames
    if (!full.names) file <- basename(file)

    return(data.frame(filename = file, single = round(singleton, 3), two = round(doubleton, 3), three = round(triple, 3), four = round(quadruple, 3), five = round(quintuple, 3), six = round(sextuple, 3), multiple = round(multiton, 3)))

  }


  # ------------------------------------------------------------------
  # apply function
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    stop("No LAS/LAZ/COPC files found.")
  }

  data.table::rbindlist(lapply(files, get_penetration_per_file))
}
