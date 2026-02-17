#' Get acquisition date from LAS files
#'
#' `get_date()` derives the acquisition date for LAS/LAZ/COPC files.
#'
#' This function attempts to determine the acquisition date for LASfiles from embedded GPStime in the point cloud
#' where possible (LAS 1.3+). If this is not possible the date is extracted from  processing date encoded in the LASheader.
#' If a valid CSV-file is provided the latest acquisition date prior to the processing date will be returned for files without
#' GPStime instead of the processing date.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LAS files,
#'   or a Virtual Point Cloud (.vpc) referencing these files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths;
#'   if `FALSE` (default), only base filenames are returned.
#' @param from_csv Character or NULL. If provided, should be the path to a CSV file
#'   containing acquisition dates for tiles without GPS time. The CSV must have columns
#'   `minx`, `miny` (tile lower-left coordinates in km) and `date` (YYYY-MM-DD).
#'   If NULL (default), dates for non-GPS tiles will be set to `NA`.
#' @param return_referenceyear Logical. If `TRUE`, returns the reference year instead of
#'   the acquisition date (e.g., reference year 2015 for data acquired in December 2014).
#'   Default is `FALSE`.
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{filename}{Filename of the LAS file.}
#'   \item{date}{Acquisition date (POSIXct for GPS-encoded files, Date for others)
#'                or reference year if `return_referenceyear = TRUE`.}
#'   \item{from}{Character. One of `data` (for files with valid GPStime data), `csv`
#'                (for other files if corresponding date is in CSV file) or `header`
#'                (for other files)}
#' }
#'
#' @details
#' - For LAS 1.3+ files with GPS time encoding, the function extracts the date of the first point.
#' - For older files without GPS time, if `from_csv` is provided, the function will attempt
#'   to assign the closest acquisition date prior to the processing date from the CSV file, based on tile coordinates.
#' - If neither GPStime nor CSV data is available, the date is from the LASheader (processing date).
#' - `return_referenceyear = TRUE` shifts December acquisitions to the following year
#'   to standardize reference years.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#' las_files |> get_date()
#'
#' # Using an external CSV for reference dates
#' csv_path <- system.file("extdata", "acquisition_dates_lgln.csv", package = "managelidar")
#' get_date(f, from_csv = csv_path)
get_date <- function(path, full.names = FALSE, from_csv = NULL, return_referenceyear = FALSE) {
  # Read LAS headers (always full paths internally)
  headers <- get_header(path, full.names = TRUE)

  # Identify files with GPS time
  header_info <- data.frame(
    filename = names(headers),
    is_gpstime = sapply(headers, function(hdr) hdr@PHB$`Global Encoding`$`GPS Time Type`),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  files_gpstime_true <- header_info$filename[header_info$is_gpstime]
  files_gpstime_false <- header_info$filename[!header_info$is_gpstime]

  # Internal helper to extract dates via VPC
  extract_dates_vpc <- function(files, gpstime_flag) {
    if (length(files) == 0) {
      return(data.frame(filename = character(), date = as.POSIXct(character()), gpstime = logical()))
    }

    # this will extract datetime from first points gpstimestamp and fall back to datetime in LASheader (processed) otherwise
    vpc_path <- lasR::exec(
      lasR::write_vpc(
        ofile = tempfile(fileext = ".vpc"),
        absolute_path = TRUE,
        use_gpstime = TRUE
      ),
      on = files
    )
    vpc <- yyjsonr::read_json_file(vpc_path)

    df <- data.frame(
      filename = sapply(vpc$features$assets, function(x) x$data$href),
      date = sapply(vpc$features$properties, function(x) x$datetime),
      gpstime = gpstime_flag,
      stringsAsFactors = FALSE,
      row.names = NULL
    )

    if (gpstime_flag) {
      df$date <- lubridate::ymd_hms(df$date)
    } else {
      df$date <- lubridate::ymd_hms(df$date)
      df$xmin <- sapply(vpc$features$properties, function(x) x$`proj:bbox`[1])
      df$ymin <- sapply(vpc$features$properties, function(x) x$`proj:bbox`[2])
    }

    df
  }

  # Extract dates for GPS and non-GPS files
  dates_gpstime_true <- extract_dates_vpc(files_gpstime_true, TRUE)
  dates_gpstime_true <- dates_gpstime_true |>
    dplyr::mutate(from = "data")

  dates_gpstime_false <- extract_dates_vpc(files_gpstime_false, FALSE)

  # Override non-GPS dates with CSV if provided
  if (!is.null(from_csv) && file.exists(from_csv) && nrow(dates_gpstime_false) > 0) {
    acquisitions <- read.csv(from_csv) |>
      dplyr::mutate(
        date_from_file = lubridate::ymd(date),
        minx = minx * 1000,
        miny = miny * 1000
      ) |>
      dplyr::select(minx, miny, date_from_file)

    dates_gpstime_false <- dates_gpstime_false |>
      dplyr::left_join(acquisitions, by = c("xmin" = "minx", "ymin" = "miny")) |>
      # in these cases (gpstime = FLASE) date was extracted from header, by definition this is the processing date
      # and should be later than the actual acquisition date. So we get all dates from the csv file for each tile
      # which are earlier than the processing date, from these we than get the latest date which is the closest one
      # prior to processing
      dplyr::filter(date_from_file <= date) |>
      dplyr::group_by(xmin, ymin, date) |>
      dplyr::slice_max(order_by = date_from_file, n = 1, with_ties = FALSE) |>
      dplyr::ungroup() |>
      dplyr::mutate(from = "csv") |>
      dplyr::select(filename, date = date_from_file, from)
  } else if (nrow(dates_gpstime_false) > 0) {
    dates_gpstime_false <- dates_gpstime_false |>
      dplyr::mutate(from = "header") |>
      dplyr::select(filename, date, from)
  }

  # Combine GPS and non-GPS results
  dates <- rbind(dates_gpstime_true, dates_gpstime_false)

  # Adjust to reference year if requested
  if (return_referenceyear) {
    dates <- dates |>
      dplyr::mutate(date = lubridate::year(date) + dplyr::if_else(lubridate::month(date) == 12, 1, 0))
  }

  # adjust filenames
  if (!full.names) dates$filename <- basename(dates$filename)

  return(as.data.frame(dates))
}
