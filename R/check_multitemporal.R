#' Check for multi-temporal coverage in LAS/LAZ files
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LAS files,
#'   or a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param entire_tiles Logical. If TRUE, only considers tiles that are exactly 1000x1000 m
#'   and aligned to a 1000m grid (default: TRUE)
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuaries are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#' @param full.names Logical. Whether to return full file paths (default: FALSE)
#' @param multitemporal_only Logical. If TRUE, only returns tiles with multiple
#'   observations (default: FALSE)
#'
#' @return A data.frame with columns:
#'   \item{filename}{Name or path of the file}
#'   \item{tile}{Tile identifier (xmin_ymin in km)}
#'   \item{date}{Date of observation}
#'   \item{multitemporal}{Logical indicating if tile has multiple observations}
#'   \item{observations}{Number of observations for this tile}
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
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' check_multitemporal(f)
#'
#' @export
check_multitemporal <- function(path, entire_tiles = TRUE, tolerance = 1, full.names = FALSE, multitemporal_only = FALSE) {
  # ------------------------------------------------------------------
  # Resolve files and build VPC if not provided
  # ------------------------------------------------------------------
  vpc <- resolve_vpc(path)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  # ------------------------------------------------------------------
  # Read bbox and date info from VPC
  # ------------------------------------------------------------------

  # Get extents and date per file
  # (from proj:bbox instead of geometry or bbox to reduce inaccuracies from reprojections)
  extents <- data.frame(
    filename = sapply(vpc$features$assets, function(x) x$data$href),
    xmin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[1]),
    ymin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[2]),
    xmax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[3]),
    ymax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[4]),
    crs = sapply(vpc$features$properties, function(x) x$`proj:epsg`),
    date = as.Date(sapply(vpc$features$properties, function(x) x$`datetime`)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # Check if CRS is consistent across all files
  unique_crs <- unique(extents$crs)
  if (length(unique_crs) > 1) {
    stop(
      "Multiple CRS detected in files: ", paste(unique_crs, collapse = ", "),
      ". All files must have the same CRS."
    )
  }

  # If tolerance > 0, snap extent to grid to overcome minor inaccuracies
  if (tolerance > 0) {
    cols <- c("xmin", "ymin", "xmax", "ymax")
    snap_round <- function(x, tilesize = 1000) {
      snapped <- round(x / tilesize) * tilesize
      x[abs(x - snapped) <= tolerance] <- snapped[abs(x - snapped) <= tolerance]
      as.integer(x)
    }
    extents[cols] <- lapply(extents[cols], snap_round)
  }

  # If entire_tiles = TRUE, check if tiles are 1x1 km and in regular grid
  if (entire_tiles) {
    is_valid_tile <- function(tile, tilesize = 1000) {
      dx <- tile$xmax - tile$xmin
      dy <- tile$ymax - tile$ymin

      size_ok <- dx == tilesize & dy == tilesize

      grid_ok <- tile$xmin %% tilesize == 0 &
        tile$ymin %% tilesize == 0 &
        tile$xmax %% tilesize == 0 &
        tile$ymax %% tilesize == 0

      size_ok & grid_ok
    }

    extents <- extents[is_valid_tile(extents), ]
  }

  # TODO
  # handle cases if entire_tiles = FALSE where tiles overlap partially

  # Group by tile and identify multi-temporal coverage
  tiles <- extents |>
    dplyr::mutate(tile = paste0((xmin / 1000), "_", (ymin / 1000))) |>
    dplyr::arrange(date) |>
    dplyr::group_by(tile) |>
    dplyr::mutate(
      observations = dplyr::n(),
      multitemporal = observations > 1
    ) |>
    dplyr::select(filename, tile, date, multitemporal, observations) |>
    dplyr::ungroup()

  # Filter to only multi-temporal tiles if requested
  if (multitemporal_only) {
    tiles <- tiles |> dplyr::filter(multitemporal)
  }

  # Adjust filenames
  if (!full.names) {
    tiles$filename <- basename(tiles$filename)
  }

  tiles
}
