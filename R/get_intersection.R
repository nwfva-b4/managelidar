#' Get intersecting LASfiles
#'
#' `get_intersection()` identifies LAS/LAZ/COPC files whose spatial extents
#' intersect or are spatially equal between two inputs.
#'
#' @param path1 Character. Path(s) to LAS/LAZ/COPC files, a directory, or a
#'   Virtual Point Cloud (.vpc).
#' @param path2 Character. Path(s) to LAS/LAZ/COPC files, a directory, or a
#'   Virtual Point Cloud (.vpc).
#' @param mode Character. Spatial predicate to use: `"intersects"` (default)
#'   or `"equals"`.
#' @param as_sf Logical. If `TRUE`, return results as `sf` objects;
#'   otherwise drop geometries (default).
#' @param full.names Logical. If `TRUE`, filenames are returned as full paths;
#'   otherwise base filenames (default).
#'
#' @return A named list with two elements (`path1`, `path2`), each containing
#'   a `data.frame` or `sf` object with column `filename` for intersecting
#'   or equal file extents.
#'
#' @details
#' This function simply checks for intersection between two inputs. \code{\link{is_multitemporal}}
#' in contrast is a newer addition and works with a single input (which can be a vector of multiple files/folders),
#' in most cases \code{\link{filter_first}} / \code{\link{filter_latest}} might be the best choice.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#' las_file <- list.files(folder, full.names = T, pattern = "*20230904.laz")
#' get_intersection(las_files, las_file)
get_intersection <- function(path1, path2, mode = "intersects", as_sf = FALSE, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Validate mode
  # ------------------------------------------------------------------
  mode <- match.arg(mode, choices = c("intersects", "equals"))

  # ------------------------------------------------------------------
  # Get extents as sf
  # ------------------------------------------------------------------
  ext1 <- get_spatial_extent(path1, as_sf = TRUE, full.names = full.names, verbose = FALSE)
  ext2 <- get_spatial_extent(path2, as_sf = TRUE, full.names = full.names, verbose = FALSE)

  if (nrow(ext1) == 0 || nrow(ext2) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # ------------------------------------------------------------------
  # Spatial predicate
  # ------------------------------------------------------------------
  pred_fun <- switch(mode,
    intersects = sf::st_intersects,
    equals     = sf::st_equals
  )

  idx1 <- lengths(pred_fun(ext1, ext2)) > 0
  idx2 <- lengths(pred_fun(ext2, ext1)) > 0

  res1 <- ext1[idx1, "filename", drop = FALSE]
  res2 <- ext2[idx2, "filename", drop = FALSE]

  # ------------------------------------------------------------------
  # Drop geometry if requested
  # ------------------------------------------------------------------
  if (!as_sf) {
    res1 <- sf::st_drop_geometry(res1)
    res2 <- sf::st_drop_geometry(res2)
  }

  # ------------------------------------------------------------------
  # Return named list
  # ------------------------------------------------------------------
  out <- list(path1 = res1, path2 = res2)
  out
}
