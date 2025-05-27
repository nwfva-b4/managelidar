#' Get acquisition datetime from point cloud
#'
#' `get_datetime()` calculates the earliest and latest acquisition datetime from point cloud files.
#'
#' Unfortunately this is only possible for newer (>= LAS 1.3) point cloud data, where acquisition date is encoded as adjusted standard GPS time. This can be converted to datetime. This function requires the entire point cloud to be read and thus takes long processing time, especially if applied on entire folders or large files.
#'
#' @param path A path to a laz file or a directory which contains laz files
#'
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A dataframe with file, min datetime, max datetime
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_datetime(f)
get_datetime <- function(path, full.names = FALSE, verbose = FALSE) {
  get_file_datetime <- function(file) {
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

    return(data.frame(file = file, datetime_min, datetime_max))
  }

  if (file.exists(path) && !dir.exists(path)) {
    return(as.data.frame(get_file_datetime(path)))
  } else {
    f <- list.files(path, pattern = "*.laz$", full.names = TRUE)
    return(as.data.frame(do.call(rbind, lapply(f, get_file_datetime))))
  }
}
