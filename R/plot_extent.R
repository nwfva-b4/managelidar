#' Plot the extent of LAS files
#'
#' `plot_extent` plots the spatial extent of LAS files on an interactive map.
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @return An interactive map in the viewer
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' plot_extent(f)
plot_extent <- function(path) {
  `proj:bbox` <- `proj.wkt2` <- NULL
  if (endsWith(path, ".vpc")) {
    print("Using information stored in Virtual Point Cloud")
    t <- sf::st_read(path)
  } else if (utils::file_test("-d", path)) {
    print("Using directory to build temporary Virtual Point Cloud")
    ans <- lasR::exec(lasR::write_vpc(tempfile(fileext = ".vpc")), on = path)
    t <- sf::st_read(ans)
  } else if (file.exists(path) && !dir.exists(path)) {
    print("Using file to build temporary Virtual Point Cloud")
    ans <- lasR::exec(lasR::write_vpc(tempfile(fileext = ".vpc")), on = path)
    t <- sf::st_read(ans)
  } else {
    print("Use either existing Virtual Point Cloud (.vpc) or folder which contains LAZ files.")
  }

  # remove list colum
  t <- subset(t, select = -`proj:bbox`)
  # remove long character column for plotting
  t <- subset(t, select = -`proj.wkt2`)
  # drop M and Z value for plotting
  t <- sf::st_zm(t)

  t$date <- as.character(as.Date(t$datetime, format = "%Y-%m-%d"))


  mapview::mapviewOptions(basemaps = "OpenTopoMap")
  mapview::mapview(t, alpha.regions = 0, label = "date")
}
