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
#' @param out_file Optional. Path where the filtered VPC should be saved.
#'   If NULL (default), returns the VPC as an R object.
#'   If provided, saves to file and returns the file path.
#'   Must have `.vpc` extension and must not already exist.
#'   File is only created if filtering returns results.
#'
#' @return If `out_file` is NULL, returns a VPC object (list) containing only
#'   features within the temporal range. If `out_file` is provided and results
#'   exist, returns the path to the saved `.vpc` file. Returns NULL invisibly
#'   if no features match the filter.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Filter by single day (all features from that day)
#' las_files |> filter_temporal("2024-03-27")
#'
#' # Filter by month (all features from March 2024)
#' las_files |> filter_temporal("2024-03")
#'
#' # Filter by year (all features from 2024)
#' las_files |> filter_temporal("2024")
#'
#' # Filter by explicit date range
#' las_files |> filter_temporal("2024-03-01", "2024-03-31")
#'
#' # Filter by datetime range
#' las_files |> filter_temporal("2024-03-27T00:00:00Z", "2024-03-27T12:00:00Z")
#'
#' # Using Date objects
#' las_files |> filter_temporal(as.Date("2024-03-27"))
#'
#' # Save to file
#' las_files |> filter_temporal("2024-03", out_file = "march.vpc")
#' }
filter_temporal <- function(path, start, end = NULL, out_file = NULL) {
  # Validate out_file if provided
  if (!is.null(out_file)) {
    if (tolower(fs::path_ext(out_file)) != "vpc") {
      stop("out_file must have .vpc extension")
    }
    if (fs::file_exists(out_file)) {
      stop("Output file already exists: ", out_file)
    }
  }

  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  if (nrow(vpc$features) == 0) {
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

  # Return based on out_file parameter
  if (is.null(out_file)) {
    return(vpc)
  } else {
    yyjsonr::write_json_file(vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
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
  # If end is provided, normalize both independently
  if (!is.null(end)) {
    return(list(
      start = normalize_datetime(start),
      end = normalize_datetime(end)
    ))
  }

  # End is NULL - determine based on start granularity

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

#' Internal helper to normalize datetime inputs (for explicit end dates)
#'
#' @param dt POSIXct, Date, or character datetime
#'
#' @return POSIXct object in UTC
#'
#' @keywords internal
normalize_datetime <- function(dt) {
  if (inherits(dt, "POSIXct")) {
    # Convert to UTC if not already
    return(lubridate::with_tz(dt, "UTC"))
  }

  if (inherits(dt, "Date")) {
    # Convert Date to POSIXct at end of day
    return(as.POSIXct(paste0(as.character(dt), " 23:59:59"), tz = "UTC"))
  }

  if (is.character(dt)) {
    # Try parsing as ISO 8601 datetime
    parsed <- tryCatch(
      as.POSIXct(dt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      error = function(e) NULL
    )

    if (!is.null(parsed) && !is.na(parsed)) {
      return(parsed)
    }

    # Try parsing as date only (end of day)
    parsed <- tryCatch(
      as.POSIXct(paste0(dt, " 23:59:59"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
      error = function(e) NULL
    )

    if (!is.null(parsed) && !is.na(parsed)) {
      return(parsed)
    }

    stop(
      "Could not parse datetime string: ", dt,
      "\nExpected format: 'YYYY-MM-DD' or 'YYYY-MM-DDTHH:MM:SSZ'"
    )
  }

  stop("Unsupported datetime type. Use POSIXct, Date, or character string.")
}
