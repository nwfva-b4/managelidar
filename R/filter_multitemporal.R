#' Filter to multi-temporal tiles
#'
#' Identifies and filters tiles that have been observed multiple times
#' (multi-temporal coverage), returning a VPC with only those tiles.
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param entire_tiles Logical. If TRUE, only considers tiles that are exactly 1000x1000 m
#'   and aligned to a 1000m grid (default: TRUE)
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuracies are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#'
#' @return A VPC object (list) containing only tiles with multiple temporal observations.
#'   Returns NULL invisibly if no multi-temporal tiles are found.
#'
#' @details
#' This function identifies tiles that have been observed multiple times (multi-temporal
#' coverage). It reads extent and date information from a VPC (Virtual Point Cloud) file,
#' optionally snaps coordinates to a regular grid, and groups observations by spatial extent.
#'
#' When \code{entire_tiles = TRUE}, only tiles that are exactly 1000x1000 m and
#' aligned to a 1000 m grid are included in the analysis.
#'
#' When \code{tolerance > 0}, coordinates within that distance of a grid line are
#' snapped to handle minor floating point inaccuracies.
#'
#' \strong{Important:} The returned VPC contains \emph{all} observations for multi-temporal
#' tiles, meaning multiple files may reference the same spatial tile. This is typically
#' not suitable for direct processing in most workflows in lasR, as data will be processed together.
#' E.g. creating a Canopy Height Model based on multi-temporal VPCs will result in a single CHM raster based on
#' lidar data from all acquisitions instead of a separate CHM raster for each acquisition time.
#'
#' Usually you want to use \code{\link{filter_first}} or \code{\link{filter_latest}} instead.
#'
#' This intermediate filtering step might be useful when you need to:
#' \itemize{
#'   \item Identify which tiles have multi-temporal data before selecting a time period
#'   \item Explicitly want to work with combined multi-temporal data
#' }
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#'
#' # Identify multi-temporal tiles
#' vpc_multi <- filter_multitemporal(f)
#'
#'
#' # Or chain filters for specific workflows:
#' vpc <- f |>
#'   filter_multitemporal() |>
#'   filter_temporal("2024") |>
#'   filter_latest()
#'
#' @seealso \code{\link{filter_first}}, \code{\link{filter_latest}},
#'   \code{\link{filter_spatial}}, \code{\link{resolve_vpc}}, \code{\link{is_multitemporal}}
#'
#' @export
filter_multitemporal <- function(path, entire_tiles = TRUE, tolerance = 1) {

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

  # Analyze tiles for multi-temporal coverage
  tiles <- is_multitemporal(path = vpc, entire_tiles = entire_tiles,
                            tolerance = tolerance,
                            multitemporal_only = TRUE,
                            full.names = TRUE)

  if (nrow(tiles) == 0) {
    warning("No multi-temporal tiles found")
    return(invisible(NULL))
  }

  # Get all files from multi-temporal tiles
  multitemporal_files <- tiles |>
    dplyr::pull(filename) |>
    unique()

  # Filter VPC features to multi-temporal tiles
  vpc$features <- vpc$features |>
    dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
    dplyr::filter(href %in% multitemporal_files) |>
    dplyr::select(-href)

  return(vpc)
}
