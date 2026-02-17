#' Filter to first acquisition from multi-temporal tiles
#'
#' Identifies tiles with multiple acquisitions and returns only the first (earliest)
#' acquisition for each tile as a filtered VPC.
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param entire_tiles Logical. If `TRUE` (default), only considers tiles where
#'   the entire tile area has multi-temporal coverage. If `FALSE`, includes tiles
#'   with partial multi-temporal coverage.
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuracies are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#' @param multitemporal_only Logical. If `TRUE`, only returns tiles with multiple
#'   acquisitions. If `FALSE` (default), includes all tiles.
#' @param verbose Logical. If TRUE (default), prints information about filtering results.
#'
#' @return A VPC object (list) containing only the first acquisition for each tile.
#'   Returns NULL invisibly if no features match the filter.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Resolves input paths to a VPC object
#'   \item Analyzes tiles for multi-temporal coverage
#'   \item Groups tiles by location and selects the earliest acquisition for each
#'   \item Returns a filtered VPC object
#' }
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#'
#' # get first acquisition per tile (entire tiles only, with 10m tolerance)
#' vpc <- filter_first(f, tolerance = 10)
#'
#' @seealso \code{\link{filter_latest}}, \code{\link{filter_spatial}},
#'   \code{\link{filter_multitemporal}}, \code{\link{resolve_vpc}}
#'
#' @export
#'
filter_first <- function(path, entire_tiles = TRUE, tolerance = 1, multitemporal_only = FALSE, verbose = TRUE) {
  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  n_input <- nrow(vpc$features)

  if (n_input == 0) {
    warning("No features in VPC to filter")
    return(invisible(NULL))
  }

  # Analyze tiles for multi-temporal coverage
  tiles <- is_multitemporal(
    path = vpc, entire_tiles = entire_tiles,
    tolerance = tolerance,
    multitemporal_only = multitemporal_only,
    full.names = TRUE
  )

  if (nrow(tiles) == 0) {
    warning("No tiles found matching criteria, consider increasing `tolerance` or set `entire_tiles=FALSE`")
    return(invisible(NULL))
  }

  # Get statistics before filtering
  n_tiles <- length(unique(tiles$tile))
  multitemporal_tiles <- unique(tiles$tile[tiles$multitemporal])
  n_multitemporal_tiles <- length(multitemporal_tiles)

  # Get only first acquisition of tiles
  selected_acquisitions <- tiles |>
    dplyr::group_by(tile) |>
    dplyr::arrange(date) |>
    dplyr::slice_head(n = 1)

  # Get files to keep
  files_to_keep <- selected_acquisitions |>
    dplyr::pull(filename)

  # No files selected
  if (length(files_to_keep) == 0) {
    warning("No first acquisitions found")
    return(invisible(NULL))
  }

  # Filter features of input VPC to selected files
  vpc$features <- vpc$features |>
    dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
    dplyr::filter(href %in% files_to_keep) |>
    dplyr::select(-href)

  n_output <- nrow(vpc$features)

  # Print information
  if (verbose) {
    message("Filter first acquisition")
    message(sprintf(
      "  \u25BC %d LASfiles in %d tiles (%d multi-temporal)",
      n_input, n_tiles, n_multitemporal_tiles
    ))
    message(sprintf("  \u25BC %d LASfiles retained", n_output))
  }

  return(vpc)
}
