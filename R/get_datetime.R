#' Get acquisition datetime from point cloud
#'
#' `get_datetime()` derives the acquisition datetime for LAS files.
#'
#' This function derives acquistion dates for LAS files either from inheritted data or from an external csv file. Deriving dates from internal data requires the entire point cloud to be read! Thus it takes potentially a long processing time, especially if applied on entire folders or large files.
#' Unfortunately it is only possible to derive exact acquisition date from newer (>= LAS 1.3) point cloud data, where acquisition date is encoded as adjusted standard GPS time. Otherwise, additional information on GPSweek is necessary. If `from_csv` points to a csv file with a date column and minx/miny in the same CRS than the LAS data, the date is extracted here. inst/extdata/acquisition_dates_lgln.csv contains dates for federal data in Lower Saxony.
#'
#' @param path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file paths or just the filenames (default) Whether to return the full file path or just the file name (default)
#' @param from_csv When NULL (default) the datetime will be extracted from internal LAS data, if it points to a valid csv file the datetime will be read from this file.
#' @param return_referenceyear If TRUE (FALSE is default) and a valid csv file is provided the reference year will be read from file instead of the date (e.g. referenceyear might be 2015 if data was acquired in december 2014).
##'
#' @return A data.frame with attributes `filename`, `datetime_min` and `datetime_max`
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_datetime(f)
get_datetime <- function(path, full.names = FALSE, verbose = FALSE, from_csv = NULL, return_referenceyear = FALSE) {
  get_datetime_file <- function(file) {
    fileheader <- lidR::readLASheader(file)

    if (!is.null(from_csv)) {
      acquisitions <- read.csv(from_csv)
      # calculate processing date from file header
      processing_date <- as.Date(fileheader@PHB$`File Creation Day of Year` - 1, origin = paste0(fileheader@PHB$`File Creation Year`, "-01-01"))
      # get last date before processing date from csv
      if(return_referenceyear) {
        date <- acquisitions |>
        dplyr::mutate(Flugdatum = as.Date(Flugdatum, format = "%Y-%m-%d")) |>
          dplyr::filter(
          # get data by minx miny
          floor(minx / 1000) == floor(fileheader@PHB$`Min X` / 1000),
          floor(miny / 1000) == floor(fileheader@PHB$`Min Y` / 1000),
          # get data where acquisition date is earlier than processing date
          Flugdatum <= processing_date
        ) |>
          dplyr::arrange(desc(Flugdatum)) |>
          dplyr::slice(1) |>
          dplyr::pull(referenzjahr)
      } else {
        date <- acquisitions |>
          dplyr::mutate(Flugdatum = as.Date(Flugdatum, format = "%Y-%m-%d")) |>
          dplyr::filter(
          # get data by minx miny
          floor(minx / 1000) == floor(fileheader@PHB$`Min X` / 1000),
          floor(miny / 1000) == floor(fileheader@PHB$`Min Y` / 1000),
          # get data where acquisition date is earlier than processing date
          Flugdatum <= processing_date
        ) |>
        dplyr::arrange(desc(Flugdatum)) |>
          dplyr::slice(1) |>
          dplyr::pull(Flugdatum)
      }


      # Check if any matches were found
      if (length(date) == 0) {
        datetime_min <- as.Date(NA)
        datetime_max <- as.Date(NA)
      } else {
        datetime_min <- date
        datetime_max <- date
      }
    } else {
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
          print("Not possible to get acqusition datetime correctly from LAS file, setting to NA")
        }

        datetime_min <- as.Date(NA)
        datetime_max <- as.Date(NA)
      }
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
