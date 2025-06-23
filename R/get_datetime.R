#' Get acquisition datetime from point cloud
#'
#' `get_datetime()` calculates the earliest and latest acquisition datetime from point cloud files.
#'
#' This function requires the entire point cloud to be read! Thus it takes potentially a long processing time, especially if applied on entire folders or large files.
#' Unfortunately it is only possible to derive exact acquisition date from newer (>= LAS 1.3) point cloud data, where acquisition date is encoded as adjusted standard GPS time. Otherwise, additional information on GPSweek is necessary.
#'
#' @param path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file path or just the file name (default)
##'
#' @return A dataframe returning `filename`, `datetime_min` `datetime_max`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_datetime(f)

get_datetime <- function(path, full.names = FALSE, verbose = FALSE){

  get_datetime_file <- function(file){
    fileheader <- lidR::readLASheader(file)

    if (fileheader$`Global Encoding`$`GPS Time Type`) {

      if (verbose) {
        print("Reading GPStime from Point Cloud")
      }

      f <- lidR::readLAS(file, select = "gpstime", filter = "-keep_first")

      gps_epoch <- as.POSIXct("1980-01-06 00:00:00", tz = "UTC")
      datetime_min <- gps_epoch + min(f@data$gpstime[f@data$gpstime > 0]) + 1e9
      datetime_max <- gps_epoch + max(f@data$gpstime) + 1e9
    } else {

      if (verbose) {
        print("Not possible to get acqusition datetime correctly from file, setting to NA")
      }

      datetime_min <- NA
      datetime_max <- NA
    }

    if (full.names == FALSE) {
      file <- basename(file)
    }

    return(data.frame(filename = file, datetime_min, datetime_max))


  }

  if (file.exists(path) && !dir.exists(path)) {

    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      return(as.data.frame(do.call(rbind, lapply(f, get_datetime_file))))
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      return(as.data.frame(get_datetime_file(path)))
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {

    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_datetime_file))))
  } else {
    stop("Path does not exist: ", path)
  }


}







