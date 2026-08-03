#' Compute the pulse penetration ratio for LASfiles
#'
#' `get_penetration()` computes approximate pulse penetration ratios for
#' LASfiles using information stored in the header.
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
#'     \item Virtual Point Cloud files (`.vpc`) referencing LASfiles
#'   }
#'
#' @param full.names Logical. If `TRUE`, return full file paths in the
#'   `filename` column. If `FALSE` (default), only the base file names
#'   are returned.
#'
#' @return
#' A `data.frame` with one row per input file and the following columns:
#' \describe{
#'   \item{filename}{File name or full path of the LASfile}
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
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")
#'
#' las_files |> get_penetration()
#'
get_penetration <- function(path, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Read headers (single I/O layer)
  # ------------------------------------------------------------------
  headers <- get_header(path, full.names = full.names)

  if (is.null(headers)) {
    return(invisible(NULL))
  }

  # ------------------------------------------------------------------
  # Compute penetration ratios per file
  # ------------------------------------------------------------------
  results <- lapply(seq_along(headers), function(i) {
    fileheader <- headers[[i]]
    returns_by_count <- fileheader$`Number of points by return`
    n_bins <- length(returns_by_count)

    # returns NA for return-count bins the header doesn't report, rather
    # than throwing "subscript out of bounds"
    return_count <- function(idx) if (n_bins >= idx) returns_by_count[[idx]] else NA_real_

    pulses <- return_count(1)

    data.frame(
      filename = names(headers)[i],
      single = round((return_count(1) - return_count(2)) / pulses, 3),
      two = round((return_count(2) - return_count(3)) / pulses, 3),
      three = round((return_count(3) - return_count(4)) / pulses, 3),
      four = round((return_count(4) - return_count(5)) / pulses, 3),
      five = round((return_count(5) - return_count(6)) / pulses, 3),
      six = round((return_count(6) - return_count(7)) / pulses, 3),
      multiple = round(return_count(2) / pulses, 3),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })

  combine_file_results(results)
}
