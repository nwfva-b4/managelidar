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
#' @param out_file Optional. Path where the filtered VPC should be saved.
#'   If NULL (default), returns the VPC as an R object.
#'   If provided, saves to file and returns the file path.
#'   Must have `.vpc` extension and must not already exist.
#'   File is only created if filtering returns results.
#'
#' @return If `out_file` is NULL, returns a VPC object (list) containing only
#'   the first acquisition for each tile. If `out_file` is provided and results
#'   exist, returns the path to the saved `.vpc` file. Returns NULL invisibly
#'   if no features match the filter.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Resolves input paths to a VPC object
#'   \item Checks for multi-temporal coverage using \code{\link{filter_multitemporal}}
#'   \item Groups tiles by location and selects the earliest acquisition for each
#'   \item Returns either a VPC object or writes a filtered VPC file
#' }
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' vpc <- filter_first(f)
#'
#' @seealso \code{\link{filter_latest}}, \code{\link{filter_spatial}},
#'   \code{\link{filter_multitemporal}}, \code{\link{resolve_vpc}}
#'
#' @export
#'
filter_first <- function(path, entire_tiles = TRUE, tolerance = 1, multitemporal_only = FALSE, out_file = NULL) {

  # Validate out_file if provided
  if (!is.null(out_file)) {
    if (tolower(fs::path_ext(out_file)) != "vpc") {
      stop("out_file must have .vpc extension")
    }
    if (fs::file_exists(out_file)) {
      stop("Output file already exists: ", out_file)
    }
  }

  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  if (nrow(vpc$features) == 0) {
    warning("No features in VPC to filter")
    return(invisible(NULL))
  }

  # Get multi-temporal tile information
  tiles <- is_multitemporal(path = vpc, entire_tiles = entire_tiles, 
                                tolerance = tolerance, 
                                multitemporal_only = multitemporal_only, 
                                full.names = TRUE)

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

  # Return based on out_file parameter
  if (is.null(out_file)) {
    return(vpc)
  } else {
    yyjsonr::write_json_file(vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
}
