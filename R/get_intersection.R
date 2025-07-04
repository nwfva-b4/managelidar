#' Get intersecting LAS files
#'
#' @param path1 The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @param path2 The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @param mode Either 'intersects' (default) or 'equals'.
#' @param as_sf (boolean) Whether to return the dataframe as spatials features data.frame or not (default).
#' @param full.names Whether to return the full file paths or just the filenames (default)
#'
#' @returns A list of 2 data.frames with attribute `filename` of all intersecting or equal file extents between `path1` and `path2`, optionally as spatial features data.frame.
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' file <- list.files(folder, full.names = T)[1]
#' get_intersection(folder, file)
get_intersection <- function(path1, path2, mode = "intersects", as_sf = FALSE, full.names = FALSE) {
  # get extents
  ext1 <- managelidar::get_extent(path1, as_sf = TRUE, full.names = full.names)
  ext2 <- managelidar::get_extent(path2, as_sf = TRUE, full.names = full.names)

  if (mode == "intersects") {
    # get intersection
    intersection1 <- ext1[lengths(sf::st_intersects(ext1, ext2)) > 0, "filename"]
    intersection2 <- ext2[lengths(sf::st_intersects(ext2, ext1)) > 0, "filename"]
  } else if (mode == "equals") {
    # get equal
    intersection1 <- ext1[lengths(sf::st_equals(ext1, ext2)) > 0, "filename"]
    intersection2 <- ext2[lengths(sf::st_equals(ext2, ext1)) > 0, "filename"]
  } else {
    stop("mode must be either 'intersects' or 'equals'")
  }

  if (as_sf == FALSE) {
    # drop geometries
    intersection1 <- sf::st_drop_geometry(intersection1)
    intersection2 <- sf::st_drop_geometry(intersection2)
  }

  # return named list
  intersection <- list(intersection1, intersection2)
  names(intersection) <- c("path1", "path2")
  return(intersection)
}
