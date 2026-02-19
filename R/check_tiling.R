#' Check if tiles are valid (correct size and aligned to grid)
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LASfiles,
#'   or a Virtual Point Cloud (.vpc) referencing LASfiles.
#' @param tilesize Numeric. Expected tile size in units (default: 1000)
#' @param tolerance Numeric. Tolerance in coordinate units for snapping extents to grid
#'   (default: 1, submeter inaccuaries are ignored). If > 0, coordinates within this distance of a grid line will be
#'   snapped before processing. Set to 0 to disable snapping.
#' @param full.names Logical. Whether to return full file paths (default: FALSE)
#'
#' @return A data.frame with columns:
#'   \item{filename}{Name of the file}
#'   \item{size_ok}{Logical indicating if tile has correct dimensions}
#'   \item{grid_ok}{Logical indicating if tile is aligned to grid}
#'   \item{valid}{Logical indicating if tile is both correct size and aligned}
#'
#' @details
#' When \code{tolerance > 0}, coordinates within that distance of a grid
#' line will be snapped to that grid line before validation. This helps handle
#' minor floating point inaccuracies or small coordinate errors while preserving
#' coordinates that are genuinely misaligned.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' # check tiling scheme with 10m tolerance
#' las_files |> check_tiling(tolerance = 10)
#'
check_tiling <- function(path, tilesize = 1000, full.names = FALSE, tolerance = 1) {
  ext <- get_spatial_extent(path, full.names = full.names, verbose = FALSE)

  # Snap to grid if tolerance > 0
  if (tolerance > 0) {
    cols <- c("xmin", "ymin", "xmax", "ymax")
    snap_round <- function(x) {
      snapped <- round(x / tilesize) * tilesize
      x[abs(x - snapped) <= tolerance] <- snapped[abs(x - snapped) <= tolerance]
      as.integer(x)
    }
    ext[cols] <- lapply(ext[cols], snap_round)
  }

  dx <- ext$xmax - ext$xmin
  dy <- ext$ymax - ext$ymin

  size_ok <- dx == tilesize & dy == tilesize

  grid_ok <- ext$xmin %% tilesize == 0 &
    ext$ymin %% tilesize == 0 &
    ext$xmax %% tilesize == 0 &
    ext$ymax %% tilesize == 0

  valid <- size_ok & grid_ok

  data.frame(
    filename = ext$filename,
    size_ok = size_ok,
    grid_ok = grid_ok,
    valid = valid
  )
}
