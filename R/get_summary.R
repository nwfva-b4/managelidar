#' Get the point cloud summary of LAS files
#'
#' `get_summary` derives information for LAS files, such as number of points per class and histogram distribution of z or intensity values.
#'
#' The function needs to read the actual point cloud data!
#' To speed up the processing the function reads just a sample of points, which is slower than just reading the header information but much faster than reading the entire file.
#' But the results are thus only valid for the subsample of points and do not necessarily reflect the entire file.
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#' @param full.names  Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default).
#'
#' @returns A named list of summary information (`npoints`, `nsingle`, `nwithheld`, `nsynthetic`, `npoints_per_return`, `npoints_per_class`, `z_histogram`, `i_histogram`, `crs`, `epsg`)
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_summary(f)
#'
get_summary <- function(path, full.names = FALSE) {
  get_summary_file <- function(file) {
    if (endsWith(file, ".copc.laz")) {
      # read first hierachies if COPC
      ans <- lasR::exec(lasR::reader(copc_depth = 1) + lasR::summarise(), on = file)
    } else if (endsWith(file, ".las") || endsWith(file, ".laz")) {
      # read sample subset in center if las/laz
      header <- lidR::readLASheader(file)
      xc <- header$`Min X` + (header$`Max X` - header$`Min X`) / 2
      yc <- header$`Min Y` + (header$`Max Y` - header$`Min Y`) / 2
      ans <- lasR::exec(lasR::reader_circles(xc, yc, 8) + lasR::summarise(), on = file)
    }

    if (full.names == FALSE) {
      file <- basename(file)
    }

    return(list(filename = file, summary = ans))
  }

  if (file.exists(path) && !dir.exists(path)) {
    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      result <- lapply(f, get_summary_file)
      names(result) <- sapply(result, function(x) basename(x$file))
      return(result)
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      result <- list(get_summary_file(path))
      names(result) <- basename(result[[1]]$file)
      return(result)
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {
    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    result <- lapply(f, get_summary_file)
    names(result) <- sapply(result, function(x) basename(x$file))
    return(result)
  } else {
    stop("Path does not exist: ", path)
  }
}
