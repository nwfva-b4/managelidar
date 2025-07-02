#' Get the spatial extent of LAS files
#'
#' `get_extent` uses min and max values of spatial extent defined in the header of lasfiles.
#'
#' @param path path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#' @param as_sf Whether to return the dataframe as spatial features
#'
#' @return A data.frame with attributes `filename`, `xmin`, `xmax`, `ymin` and `ymax`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_extent(f)
get_extent <- function(path, as_sf = FALSE, full.names = FALSE) {

  # Virtual Point Cloud
  if (tools::file_ext(path) == "vpc") {
    print("Using information stored in Virtual Point Cloud")
    ans <- path
  } else if (
  # LAZ file
  tools::file_ext(path) %in% c("las", "laz")) {
    print("Using file to build temporary Virtual Point Cloud")
    ans <- lasR::exec(lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path =TRUE), on = path)
  } else if (

  # Folder Path
  dir.exists(path)) {
    print("Using directory to build temporary Virtual Point Cloud")
    ans <- lasR::exec(lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path =TRUE), on = path)
  } else {
    stop("Path does not exist: ", path, "Use either existing Virtual Point Cloud (.vpc), LAS file, or folder which contains LAS files.")
  }

  # read info from vpc
  vpc <- yyjsonr::read_json_file(ans)
  t <- data.frame(filename = sapply(vpc$features$assets, function(x) x$data$href),
                  xmin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[[1]]),
                  xmax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[[3]]),
                  ymin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[[2]]),
                  ymax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[[4]])
  )



  # optionally as spatial features
  if (as_sf) {
    t <- sf::st_sf(t, geometry = sf::st_read(ans)$geometry)
    t <- sf::st_zm(t)
  }

  # return basename or full name
  if (full.names == FALSE){
    t$filename <- basename(t$filename)
  }

  return(t)
}


