#' Get the temporal extent of LASfiles
#'
#' Extracts the temporal extent (acquisition dates) from LASfiles. Can return
#' dates per file or the combined date range of all files.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory, or a Virtual
#'   Point Cloud (.vpc) referencing these files.
#' @param per_file Logical. If `TRUE` (default), returns dates per file. If `FALSE`,
#'   returns combined date range of all files.
#' @param fix_false_gpstime Logical. If `TRUE` (default), detects files that claim
#'   GPS time encoding in their header but contain week-second timestamps instead
#'   of standard GPS time. Such files produce spurious dates in the range
#'   2011-09-14 to 2011-09-21 when decoded as GPS time. Affected files are
#'   silently reclassified as non-GPS and their dates are resolved via CSV or
#'   header fallback instead.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths;
#'   otherwise base filenames (default). Only used when `per_file = TRUE`.
#' @param from_csv Character or NULL. If provided, path to a CSV file containing
#'   acquisition dates for tiles without GPS time. The CSV must have columns
#'   `minx`, `miny` (tile coordinates in km) and `date` (YYYY-MM-DD).
#'   If NULL (default), dates for non-GPS tiles are extracted from file headers.
#' @param return_referenceyear Logical. If `TRUE`, returns the reference year instead
#'   of the acquisition date (e.g., reference year 2015 for data acquired in
#'   November or December 2014). Default is `FALSE`.
#' @param verbose Logical. If `TRUE` (default), prints temporal extent information.
#'
#' @return When `per_file = TRUE`: A `data.frame` with columns:
#' \describe{
#'   \item{filename}{Filename of the LASfile.}
#'   \item{date}{Acquisition date (Date object) or reference year (numeric)
#'               if `return_referenceyear = TRUE`.}
#'   \item{date_source}{Character. One of `data` (files with valid GPStime), `csv`
#'                (matched from CSV file), or `header` (from file header).}
#' }
#' When `per_file = FALSE`: A single-row data.frame with `start` and `end`
#' (Date objects or numeric years depending on `return_referenceyear`).
#'
#' @details
#' For LAS 1.3+ files with GPS time encoding, the function extracts the date from
#' the first point. For older files without GPS time, if `from_csv` is provided,
#' the function assigns the closest acquisition date prior to the processing date
#' from the CSV file based on tile coordinates. Otherwise, the date is extracted
#' from the LAS header (processing date).
#'
#' When `return_referenceyear = TRUE`, November and December acquisitions are
#' shifted to the following year to standardize reference years.
#'
#' @export
#'
#' @seealso \code{\link{get_spatial_extent}}, \code{\link{filter_temporal}}
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = TRUE, pattern = "*.laz")
#'
#' # Get dates per file
#' las_files |> get_temporal_extent()
#'
#' # Get combined date range
#' las_files |> get_temporal_extent(per_file = FALSE)
#'
#' # Get reference years
#' las_files |> get_temporal_extent(return_referenceyear = TRUE)
#'
#' # Using CSV for reference dates
#' csv_path <- system.file("extdata", "acquisition_dates.csv", package = "managelidar")
#' get_temporal_extent(folder, from_csv = csv_path)
#'
get_temporal_extent <- function(path, per_file = TRUE, full.names = FALSE,
                                from_csv = NULL, return_referenceyear = FALSE,
                                fix_false_gpstime = TRUE, verbose = TRUE) {
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
      return(data.frame(filename = character(), date = as.Date(character()), gpstime = logical()))
    }

    if (gpstime_flag) {
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
        date = as.Date(sapply(vpc$features$properties, function(x) x$datetime)),
        gpstime = gpstime_flag,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }



    if (!gpstime_flag) {
      vpc_path <- lasR::exec(
        lasR::write_vpc(
          ofile = tempfile(fileext = ".vpc"),
          absolute_path = TRUE,
          use_gpstime = FALSE # force to get date from header
        ),
        on = files
      )
      vpc <- yyjsonr::read_json_file(vpc_path)

      df <- data.frame(
        filename = sapply(vpc$features$assets, function(x) x$data$href),
        date = as.Date(sapply(vpc$features$properties, function(x) x$datetime)),
        gpstime = gpstime_flag,
        # add xmin/ymin to merge dates from vpc
        xmin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[1]),
        ymin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[2]),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }

    df
  }

  # Extract dates for GPS and non-GPS files
  dates_gpstime_true <- extract_dates_vpc(files_gpstime_true, TRUE)

  # Detect files with false GPS time encoding: dates fall in the suspicious range
  # caused by timestamps being week-seconds (0 to 604800) misinterpreted as GPS time.
  # These files incorrectly set the GPS Time Type bit in the Global Encoding header field,
  # so their point timestamps are actually seconds-of-week (0-604800) rather than
  # adjusted standard GPS time. When decoded as GPS time this always yields dates
  # in the narrow window 2011-09-14 to 2011-09-21 (one GPS week).
  if (fix_false_gpstime && nrow(dates_gpstime_true) > 0) {
    suspicious_range <- as.Date(c("2011-09-14", "2011-09-21"))
    is_suspicious <- !is.na(dates_gpstime_true$date) &
      dates_gpstime_true$date >= suspicious_range[1] &
      dates_gpstime_true$date <= suspicious_range[2]

    if (any(is_suspicious)) {
      if (verbose) {
        message(sprintf(
          "  %d file(s) claim GPS time encoding but have suspicious dates (week-second artifact); treating as non-GPS.",
          sum(is_suspicious)
        ))
      }
      # Move suspicious files into the non-GPS bucket for proper date handling
      files_gpstime_false <- c(files_gpstime_false, dates_gpstime_true$filename[is_suspicious])
      dates_gpstime_true  <- dates_gpstime_true[!is_suspicious, ]
    }
  }

  dates_gpstime_true <- dates_gpstime_true |>
    dplyr::mutate(date_source = "data")

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
      dplyr::filter(is.na(date_from_file) | date_from_file <= date) |>
      dplyr::group_by(xmin, ymin, date) |>
      dplyr::slice_max(order_by = date_from_file, n = 1, with_ties = FALSE) |>
      dplyr::ungroup() |>
      dplyr::mutate(
        date_source = dplyr::if_else(is.na(date_from_file), "header", "csv"),
        date = dplyr::if_else(is.na(date_from_file), date, date_from_file)
      ) |>
      dplyr::select(filename, gpstime, date, date_source)
  } else if (nrow(dates_gpstime_false) > 0) {
    dates_gpstime_false <- dates_gpstime_false |>
      dplyr::mutate(date_source = "header") |>
      dplyr::select(filename, gpstime, date, date_source)
  }
  # Combine GPS and non-GPS results
  dates <- rbind(dates_gpstime_true, dates_gpstime_false)

  # Check for missing dates
  missing_dates <- is.na(dates$date)
  if (any(missing_dates)) {
    warning(sum(missing_dates), " file(s) missing valid date")
    dates <- dates[!missing_dates, ]
  }

  n_files <- nrow(dates)

  if (n_files == 0) {
    warning("No files with valid dates")
    return(invisible(NULL))
  }

  # Adjust to reference year if requested (before calculating extent)
  if (return_referenceyear) {
    dates <- dates |>
      dplyr::mutate(date = lubridate::year(date) +
                      dplyr::if_else(lubridate::month(date) %in% c(11, 12), 1, 0))
  }

  # Calculate overall temporal extent
  start_val <- min(dates$date)
  end_val <- max(dates$date)

  # Print information
  if (verbose) {
    message("Get temporal extent")
    message(sprintf("  \u25BC %d LASfiles", n_files))
    if (return_referenceyear) {
      if (start_val == end_val) {
        message(sprintf("  Temporal extent: %d", start_val))
      } else {
        message(sprintf("  Temporal extent: %d to %d", start_val, end_val))
      }
    } else {
      if (start_val == end_val) {
        message(sprintf("  Temporal extent: %s", format(start_val, "%Y-%m-%d")))
      } else {
        message(sprintf("  Temporal extent: %s to %s",
                        format(start_val, "%Y-%m-%d"),
                        format(end_val, "%Y-%m-%d")))
      }
    }
  }

  # If per_file = FALSE, return combined extent
  if (!per_file) {
    combined_ext <- data.frame(
      start = start_val,
      end = end_val,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
    return(combined_ext)
  }

  # Adjust filenames for per_file mode
  if (!full.names) {
    dates$filename <- basename(dates$filename)
  }

  as.data.frame(dates)
}
