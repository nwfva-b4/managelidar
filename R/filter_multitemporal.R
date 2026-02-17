#' Filter tiles by number of temporal observations
#'
#' Filters tiles based on the number of temporal observations, returning a VPC with
#' tiles that have a specific number of files or multiple observations.
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param n Numeric or NULL. Number of observations to filter by:
#'   \itemize{
#'     \item NULL (default): Returns all tiles with 2 or more observations (multi-temporal)
#'     \item 1: Returns tiles with exactly 1 observation (mono-temporal)
#'     \item 2, 3, etc.: Returns tiles with exactly that many observations
#'   }
#' @param entire_tiles Logical. If TRUE (default), only considers tiles that are exactly 1000x1000 m
#'   and aligned to a 1000m grid.
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuracies are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#' @param verbose Logical. If TRUE (default), prints information about filtering results.
#'
#' @return A VPC object (list) containing only tiles matching the temporal criteria.
#'   Returns NULL invisibly if no matching tiles are found.
#'
#' @details
#' This function identifies tiles based on their temporal coverage. It reads extent and
#' date information from a VPC (Virtual Point Cloud) file, optionally snaps coordinates
#' to a regular grid, and groups observations by spatial extent.
#'
#' When \code{entire_tiles = TRUE}, only tiles that are exactly 1000x1000 m and
#' aligned to a 1000 m grid are included in the analysis.
#'
#' When \code{tolerance > 0}, coordinates within that distance of a grid line are
#' snapped to handle minor floating point inaccuracies.
#'
#' \strong{When n = NULL (multi-temporal):}
#'
#' The returned VPC contains \emph{all} observations for multi-temporal
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
#'   \item Filter to tiles with exactly n observations for quality control
#'   \item Explicitly want to work with combined multi-temporal data
#'   \item Isolate mono-temporal tiles (n = 1) for separate processing
#' }
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#'
#' # Get all multi-temporal (2+ observations) tiles (entire tiles only, with 10m tolerance)
#' vpc_multi <- filter_multitemporal(f, tolerance = 10)
#'
#' # Get only mono-temporal (exactly 1 observation) tiles  (entire tiles only, with 10m tolerance)
#' vpc_mono <- filter_multitemporal(f, entire_tiles = FALSE, tolerance = 10, n = 1)
#'
#' # Get tiles with exactly 3 observations (entire tiles only, with 10m tolerance)
#' vpc_three <- filter_multitemporal(f, n = 3)
#'
#' # Chain filters for specific workflows:
#' vpc <- f |>
#'   filter_multitemporal(tolerance = 10) |>
#'   filter_temporal("2024") |>
#'   filter_latest(tolerance = 10)
#'
#' @seealso \code{\link{filter_first}}, \code{\link{filter_latest}},
#'   \code{\link{filter_spatial}}, \code{\link{resolve_vpc}}, \code{\link{is_multitemporal}}
#'
#' @export
filter_multitemporal <- function(path, n = NULL, entire_tiles = TRUE, tolerance = 1, verbose = TRUE) {
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

  # Analyze tiles for multi-temporal coverage (get all tiles, not just multitemporal)
  tiles <- is_multitemporal(
    path = vpc, entire_tiles = entire_tiles,
    tolerance = tolerance,
    multitemporal_only = FALSE,
    full.names = TRUE
  )
  if (nrow(tiles) == 0) {
    warning("No tiles found matching criteria, consider increasing `tolerance` or set `entire_tiles=FALSE`")
    return(invisible(NULL))
  }

  # Filter based on n parameter
  if (is.null(n)) {
    # Multi-temporal: 2 or more observations
    tiles_filtered <- tiles |> dplyr::filter(observations >= 2)
    filter_type <- "multi-temporal"
  } else {
    # Specific number of observations
    tiles_filtered <- tiles |> dplyr::filter(observations == n)
    if (n == 1) {
      filter_type <- "mono-temporal"
    } else {
      filter_type <- sprintf("%d-temporal", n)
    }
  }

  if (nrow(tiles_filtered) == 0) {
    if (is.null(n)) {
      warning("No multi-temporal tiles found")
    } else {
      warning("No tiles with exactly ", n, " observation(s) found")
    }
    return(invisible(NULL))
  }

  # Get statistics
  n_tiles_total <- length(unique(tiles$tile))
  n_multitemporal_all <- sum(unique(tiles$tile) %in% unique(tiles$tile[tiles$multitemporal]))
  n_tiles_filtered <- length(unique(tiles_filtered$tile))

  observations_per_tile <- tiles_filtered |>
    dplyr::group_by(tile) |>
    dplyr::summarise(n_obs = dplyr::n(), .groups = "drop")
  min_obs <- min(observations_per_tile$n_obs)
  max_obs <- max(observations_per_tile$n_obs)
  avg_obs <- mean(observations_per_tile$n_obs)

  # Get all files from filtered tiles
  files_to_keep <- tiles_filtered |>
    dplyr::pull(filename) |>
    unique()

  # Filter VPC features to selected tiles
  vpc$features <- vpc$features |>
    dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
    dplyr::filter(href %in% files_to_keep) |>
    dplyr::select(-href)

  n_output <- nrow(vpc$features)

  # Print information
  if (verbose) {
    message(sprintf("Filter %s tiles", filter_type))
    message(sprintf(
      "  \u25BC %d LASfiles in %d tiles (%d multi-temporal)",
      n_input, n_tiles_total, n_multitemporal_all
    ))

    # Format files/tile info
    if (min_obs == max_obs) {
      files_info <- sprintf("(%d files/tile)", min_obs)
    } else {
      files_info <- sprintf("(%d-%d files/tile, \u00F8 %.1f)", min_obs, max_obs, avg_obs)
    }

    message(sprintf("  \u25BC %d LASfiles retained %s", n_output, files_info))
  }

  return(vpc)
}
