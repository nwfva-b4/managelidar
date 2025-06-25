#' Check if LAS files are classified
#'
#' `is_classified` derives information about point classification
#'
#' The function needs to read the actual point cloud data!
#' To speed up the processing the function reads just a sample of points, which is slower than just reading the header information but much faster than reading the entire file.
#' The results are thus only valid for the subsample of points and do not necessarily reflect the entire file.
#'
#' @param path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file path or just the file name (default)
#' @param add_classes Whether to add a list of present classes or not (default)
#'
#' @returns A dataframe returning `filename`, `classified`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' is_classified(f)
#'
is_classified <- function(path, full.names = FALSE, add_classes = FALSE) {
  is_classified_file <- function(file) {
    if (endsWith(file, ".copc.laz")) {
      # read first hierachies if COPC
      ans <- lasR::exec(lasR::reader(copc_depth = 1) + lasR::summarise(), on = file)
    } else if (endsWith(file, ".las") || endsWith(file, ".laz")) {
      # read sample subset in center if las/laz
      header <- lidR::readLASheader(file)
      xc <- header$`Min X` + (header$`Max X` - header$`Min X`) / 2
      yc <- header$`Min Y` + (header$`Max Y` - header$`Min Y`) / 2
      ans <- lasR::exec(lasR::reader_circles(xc, yc, 10) + lasR::summarise(), on = file)
    }

    # check if all points are 0
    classified <- !(all(names(ans$npoints_per_class) == "0") && length(names(ans$npoints_per_class)) == 1)

    if (full.names == FALSE) {
      file <- basename(file)
    }

    if (add_classes) {
      return(data.frame(file = file, classified = classified, classes = I(list(as.character(names(ans$npoints_per_class))))))
    } else {
      return(data.frame(file = file, classified = classified))
    }
      }

  if (file.exists(path) && !dir.exists(path)) {
    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      return(as.data.frame(do.call(rbind, lapply(f, is_classified_file))))
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      return(as.data.frame(is_classified_file(path)))
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {
    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, is_classified_file))))
  } else {
    stop("Path does not exist: ", path)
  }
}
