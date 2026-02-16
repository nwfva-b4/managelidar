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
#' @param out_file Optional. Path where the filtered VPC should be saved.
#'   If NULL (default), returns the VPC as an R object.
#'   If provided, saves to file and returns the file path.
#'   Must have `.vpc` extension and must not already exist.
#'   File is only created if filtering returns results.
#'
#' @return If `out_file` is NULL, returns a VPC object (list) containing only
#'   tiles with multiple temporal observations. If `out_file` is provided and results
#'   exist, returns the path to the saved `.vpc` file. Returns NULL invisibly
#'   if no multi-temporal tiles are found.
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
#' vpc <- filter_multitemporal(f)
#'
#' @seealso \code{\link{filter_first}}, \code{\link{filter_latest}},
#'   \code{\link{filter_spatial}}, \code{\link{resolve_vpc}}, \code{\link{is_multitemporal}}
#'
#' @export
filter_multitemporal <- function(path, entire_tiles = TRUE, tolerance = 1, out_file = NULL) {

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
    dplyr::ungroup()

  # Filter to only multi-temporal tiles
  multitemporal_files <- tiles |>
    dplyr::filter(multitemporal) |>
    dplyr::pull(filename) |>
    unique()

  # No multi-temporal tiles found
  if (length(multitemporal_files) == 0) {
    warning("No multi-temporal tiles found")
    return(invisible(NULL))
  }

  # Filter VPC features to multi-temporal tiles
  vpc$features <- vpc$features |>
    dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
    dplyr::filter(href %in% multitemporal_files) |>
    dplyr::select(-href)

  # Return based on out_file parameter
  if (is.null(out_file)) {
    return(vpc)
  } else {
    yyjsonr::write_json_file(vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
}
