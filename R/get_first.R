#' Get first acquisition from multi-temporal tiles
#'
#' Identifies tiles with multiple acquisitions and returns only the first (earliest)
#' acquisition for each tile. Can return results as a data frame or write a filtered
#' VPC file.
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param entire_tiles Logical. If `TRUE` (default), only considers tiles where
#'   the entire tile area has multi-temporal coverage. If `FALSE`, includes tiles
#'   with partial multi-temporal coverage.
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuaries are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#' @param full.names Logical. Whether to return full file paths (default: FALSE)
#' @param multitemporal_only Logical. If `TRUE`, only returns tiles with multiple
#'   acquisitions. If `FALSE` (default), includes all tiles.
#' @param out_file Optional. Path where a filtered VPC file should be saved. If
#'   `NULL` (default), returns a data frame. If provided, writes a VPC file
#'   containing only the first acquisitions and returns the file path.
#'
#' @return If `out_file` is `NULL`, returns a data frame with columns:
#'   \describe{
#'     \item{filename}{Character. Path to the LAS/LAZ file}
#'     \item{date}{Date. Acquisition date of the file}
#'   }
#'   If `out_file` is provided, returns the path to the saved VPC file.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Resolves input paths to a VPC object
#'   \item Checks for multi-temporal coverage using \code{\link{check_multitemporal}}
#'   \item Groups tiles by location and selects the earliest acquisition for each
#'   \item Returns either a summary data frame or writes a filtered VPC file
#' }
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_first(f)
#'
#' @seealso \code{\link{get_latest}}, \code{\link{check_multitemporal}}, \code{\link{resolve_vpc}}
#'
#' @export
#'
get_first <- function(path, entire_tiles = TRUE, tolerance = 1, full.names = FALSE, multitemporal_only = FALSE, out_file = NULL) {
  vpc <- resolve_vpc(path)

  tiles <- check_multitemporal(path = vpc, entire_tiles = entire_tiles, tolerance = tolerance, multitemporal_only = multitemporal_only, full.names = TRUE)

  # get only first/last acquisition of tiles with multi-temporal data
  selected_acquisitions <- tiles |>
    dplyr::group_by(tile) |>
    dplyr::arrange(date) |>
    dplyr::slice_head(n = 1)

  # Return based on out_file parameter
  if (is.null(out_file)) {
    res <- data.frame(
      filename = selected_acquisitions$filename,
      date = selected_acquisitions$date
    )

    # Adjust filenames
    if (!full.names) {
      res$filename <- basename(res$filename)
    }

    return(res)
  } else {
    if (file.exists(out_file)) {
      stop("Output file exists: ", out_file)
    }

    files_to_keep <- selected_acquisitions |>
      dplyr::pull(filename)

    # filter features of input VPC to multi-temporal tiles
    features <- vpc$features |>
      dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
      dplyr::filter(href %in% files_to_keep) |>
      dplyr::select(-href)

    vpc_multitemporal <- vpc
    vpc_multitemporal$features <- features


    jsonlite::write_json(vpc_multitemporal, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
}
