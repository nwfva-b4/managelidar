#' Get intersecting LAS files
#'
#' @param path1 path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @param path2 The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @param mode Either 'intersects' (default) or 'equals'.
#' @param full.names Whether to return the full file paths or just the filenames (default)
#'
#' @returns A spatial features data.frame with attributes `filename`, `xmin`, `xmax`, `ymin`, `ymax` of all files in `path1` which intersect files in `path2` ('intersects') or which have the same extent as files in `path2` ('equals').
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' file <- list.files(folder, full.names = T)[1]
#' get_intersection(folder, file)
get_intersection <- function(path1, path2, mode = "intersects", full.names = FALSE) {
  ext1 <- get_extent(path1, as_sf = TRUE, full.names = full.names)

  ext2 <- get_extent(path2, as_sf = TRUE, full.names = full.names)

  if (mode == "intersects") {
    return(ext1[lengths(sf::st_intersects(ext1, ext2)) > 0, ])
  } else if (mode == "equals") {
    return(ext1[lengths(sf::st_equals(ext1, ext2)) > 0, ])
  } else {
    stop("mode must be either 'intersects' or 'equals'")
  }
}
