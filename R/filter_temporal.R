#' Filter point cloud files by temporal extent
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param start POSIXct, Date, or character. Start of temporal range (inclusive).
#'   Character strings are parsed as ISO 8601 datetime (e.g., "2024-03-27" or
#'   "2024-03-27T10:30:00Z"). Can also be year ("2024"), year-month ("2024-03"),
#'   or full date ("2024-03-27").
#' @param end POSIXct, Date, or character. End of temporal range (inclusive).
#'   If NULL (default), the end is automatically determined based on the
#'   granularity of `start`:
#'   \itemize{
#'     \item Year only ("2024"): end of that year
#'     \item Year-month ("2024-03"): end of that month
#'     \item Full date ("2024-03-27"): end of that day (23:59:59)
#'     \item Full datetime: same as start (exact match)
#'   }
#' @param verbose Logical. If TRUE (default), prints information about filtering results.
#'
#' @return A VPC object (list) containing only features within the temporal range.
#'   Returns NULL invisibly if no features match the filter.
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*.laz")
#'
#' # Filter by single day (all features from that day)
#' vpc <- las_files |> filter_temporal("2024-03-27")
#'
#' # Filter by month (all features from March 2024)
#' vpc <- las_files |> filter_temporal("2024-03")
#'
#' # Filter by year (all features from 2024)
#' vpc <- las_files |> filter_temporal("2024")
#'
#' # Filter by explicit date range
#' vpc <- las_files |> filter_temporal("2024-03-01", "2024-03-31")
#'
#' # Filter by datetime range
#' vpc <- las_files |> filter_temporal("2024-03-27T00:00:00Z", "2024-03-27T12:00:00Z")
#'
#' # Using Date objects
#' vpc <- las_files |> filter_temporal(as.Date("2024-03-27"))
#'
filter_temporal <- function(path, start, end = NULL, verbose = TRUE) {
  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  n_input <- nrow(vpc$features)

  if (n_input == 0) {
    warning("No features in VPC to filter")
    return(invisible(NULL))
  }

  # Normalize start and determine end if not provided
  temporal_range <- normalize_temporal_range(start, end)
  start_time <- temporal_range$start
  end_time <- temporal_range$end

  # Extract datetime from each feature
  feature_times <- vapply(seq_len(nrow(vpc$features)), function(i) {
    dt <- vpc$features$properties[[i]]$datetime
    if (is.null(dt)) {
      return(NA_character_)
    }
    return(dt)
  }, character(1))

  # Check if any features are missing datetime
  missing_dt <- is.na(feature_times)
  if (any(missing_dt)) {
    warning(sum(missing_dt), " feature(s) missing datetime property, excluding from filter")
  }

  # Parse feature datetimes
  feature_times_parsed <- as.POSIXct(feature_times, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  # Filter features within temporal range
  keep <- !is.na(feature_times_parsed) &
    feature_times_parsed >= start_time &
    feature_times_parsed <= end_time

  # No intersections found
  if (sum(keep) == 0) {
    warning("No features within the specified temporal range")
    return(invisible(NULL))
  }

  vpc$features <- vpc$features[keep, , drop = FALSE]

  n_output <- nrow(vpc$features)

  # Print information
  if (verbose) {
    # Format date range for display - actual range of input files
    start_str_input <- format(min(feature_times_parsed, na.rm = TRUE), "%Y-%m-%d")
    end_str_input <- format(max(feature_times_parsed, na.rm = TRUE), "%Y-%m-%d")

    if (start_str_input == end_str_input) {
      date_range_input <- start_str_input
    } else {
      date_range_input <- sprintf("%s to %s", start_str_input, end_str_input)
    }

    # Format date range for output - actual range of retained files
    feature_times_kept <- feature_times_parsed[keep]
    start_str_output <- format(min(feature_times_kept), "%Y-%m-%d")
    end_str_output <- format(max(feature_times_kept), "%Y-%m-%d")

    if (start_str_output == end_str_output) {
      date_range_output <- start_str_output
    } else {
      date_range_output <- sprintf("%s to %s", start_str_output, end_str_output)
    }

    message("Filter temporal extent")
    message(sprintf("  \u25BC %d LASfiles (%s)", n_input, date_range_input))
    message(sprintf("  \u25BC %d LASfiles retained (%s)", n_output, date_range_output))
  }

  return(vpc)
}

#' Internal helper to normalize temporal range
#'
#' @param start Start datetime (various formats)
#' @param end End datetime (various formats) or NULL
#'
#' @return List with start and end POSIXct objects
#'
#' @keywords internal
normalize_temporal_range <- function(start, end = NULL) {
  # Parse start first (always parse fully to get start time)
  start_parsed <- parse_datetime_input(start, position = "start")

  # If end is provided, parse it
  if (!is.null(end)) {
    end_parsed <- parse_datetime_input(end, position = "end")
    return(list(start = start_parsed, end = end_parsed))
  }

  # End is NULL - determine based on start granularity
  # We need to re-examine the original start to determine granularity

  # Handle POSIXct
  if (inherits(start, "POSIXct")) {
    return(list(start = start, end = start))
  }

  # Handle Date
  if (inherits(start, "Date")) {
    start_time <- as.POSIXct(paste0(as.character(start), " 00:00:00"), tz = "UTC")
    end_time <- as.POSIXct(paste0(as.character(start), " 23:59:59"), tz = "UTC")
    return(list(start = start_time, end = end_time))
  }

  # Handle character strings
  if (is.character(start)) {
    # Check for year only (YYYY)
    if (grepl("^\\d{4}$", start)) {
      year <- as.integer(start)
      start_time <- as.POSIXct(paste0(year, "-01-01 00:00:00"), tz = "UTC")
      end_time <- as.POSIXct(paste0(year, "-12-31 23:59:59"), tz = "UTC")
      return(list(start = start_time, end = end_time))
    }

    # Check for year-month (YYYY-MM)
    if (grepl("^\\d{4}-\\d{2}$", start)) {
      start_time <- as.POSIXct(paste0(start, "-01 00:00:00"), tz = "UTC")
      # Calculate last day of month
      next_month <- as.POSIXct(paste0(start, "-01 00:00:00"), tz = "UTC") +
        as.difftime(31, units = "days")
      last_day <- as.POSIXct(format(next_month, "%Y-%m-01"), tz = "UTC") -
        as.difftime(1, units = "secs")
      return(list(start = start_time, end = last_day))
    }

    # Check for full datetime (YYYY-MM-DDTHH:MM:SSZ)
    if (grepl("T", start)) {
      parsed <- as.POSIXct(start, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      if (!is.na(parsed)) {
        return(list(start = parsed, end = parsed))
      }
    }

    # Check for date only (YYYY-MM-DD)
    if (grepl("^\\d{4}-\\d{2}-\\d{2}$", start)) {
      start_time <- as.POSIXct(paste0(start, " 00:00:00"), tz = "UTC")
      end_time <- as.POSIXct(paste0(start, " 23:59:59"), tz = "UTC")
      if (!is.na(start_time)) {
        return(list(start = start_time, end = end_time))
      }
    }

    stop(
      "Could not parse datetime string: ", start,
      "\nExpected format: 'YYYY', 'YYYY-MM', 'YYYY-MM-DD', or 'YYYY-MM-DDTHH:MM:SSZ'"
    )
  }

  stop("Unsupported datetime type for start. Use POSIXct, Date, or character string.")
}

#' Internal helper to parse datetime input
#'
#' @param dt POSIXct, Date, or character datetime
#' @param position Either "start" or "end" - determines whether to use beginning or end of period
#'
#' @return POSIXct object in UTC
#'
#' @keywords internal
parse_datetime_input <- function(dt, position = "start") {
  if (inherits(dt, "POSIXct")) {
    # Convert to UTC if not already
    return(lubridate::with_tz(dt, "UTC"))
  }

  if (inherits(dt, "Date")) {
    # Convert Date to POSIXct
    if (position == "start") {
      return(as.POSIXct(paste0(as.character(dt), " 00:00:00"), tz = "UTC"))
    } else {
      return(as.POSIXct(paste0(as.character(dt), " 23:59:59"), tz = "UTC"))
    }
  }

  if (is.character(dt)) {
    # Check for year only (YYYY)
    if (grepl("^\\d{4}$", dt)) {
      year <- as.integer(dt)
      if (position == "start") {
        return(as.POSIXct(paste0(year, "-01-01 00:00:00"), tz = "UTC"))
      } else {
        return(as.POSIXct(paste0(year, "-12-31 23:59:59"), tz = "UTC"))
      }
    }

    # Check for year-month (YYYY-MM)
    if (grepl("^\\d{4}-\\d{2}$", dt)) {
      if (position == "start") {
        return(as.POSIXct(paste0(dt, "-01 00:00:00"), tz = "UTC"))
      } else {
        # Calculate last day of month
        start_of_month <- as.POSIXct(paste0(dt, "-01 00:00:00"), tz = "UTC")
        next_month <- start_of_month + as.difftime(31, units = "days")
        last_day <- as.POSIXct(format(next_month, "%Y-%m-01"), tz = "UTC") -
          as.difftime(1, units = "secs")
        return(last_day)
      }
    }

    # Check for full datetime (YYYY-MM-DDTHH:MM:SSZ)
    if (grepl("T", dt)) {
      parsed <- as.POSIXct(dt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      if (!is.na(parsed)) {
        return(parsed)
      }
    }

    # Check for date only (YYYY-MM-DD)
    if (grepl("^\\d{4}-\\d{2}-\\d{2}$", dt)) {
      if (position == "start") {
        parsed <- as.POSIXct(paste0(dt, " 00:00:00"), tz = "UTC")
      } else {
        parsed <- as.POSIXct(paste0(dt, " 23:59:59"), tz = "UTC")
      }
      if (!is.na(parsed)) {
        return(parsed)
      }
    }

    stop(
      "Could not parse datetime string: ", dt,
      "\nExpected format: 'YYYY', 'YYYY-MM', 'YYYY-MM-DD', or 'YYYY-MM-DDTHH:MM:SSZ'"
    )
  }

  stop("Unsupported datetime type. Use POSIXct, Date, or character string.")
}

#' Internal helper to normalize datetime inputs (for explicit end dates) - DEPRECATED
#'
#' @param dt POSIXct, Date, or character datetime
#'
#' @return POSIXct object in UTC
#'
#' @keywords internal
normalize_datetime <- function(dt) {
  # This function is kept for backwards compatibility but now just calls parse_datetime_input
  parse_datetime_input(dt, position = "end")
}
