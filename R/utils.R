#' Check whether an EPSG code is valid
#'
#' Validates an EPSG code by checking it is non-missing, non-zero, and
#' recognised by [sf::st_crs()]. Codes that parse without error but resolve
#' to an unknown CRS (e.g. 32767, "user-defined") are also treated as invalid.
#'
#' @param epsg_code Integer. EPSG code to validate.
#'
#' @return Logical scalar: `TRUE` if the code is a recognised CRS, `FALSE`
#'   otherwise.
#'
#' @keywords internal
is_valid_crs <- function(epsg_code) {
  if (is.na(epsg_code) || epsg_code == 0L) {
    return(FALSE)
  }
  tryCatch(
    {
      !is.na(suppressWarnings(sf::st_crs(epsg_code))$epsg)
    },
    error = function(e) FALSE
  )
}

#' Combine a list of per-file result data.frames into one plain data.frame
#'
#' Used by `get_*()` functions to combine per-file metrics into a single
#' table. Uses [dplyr::bind_rows()] rather than base `rbind()` because
#' per-file error entries (e.g. from [map_las()]'s failure wrapper) can have
#' a different shape than successful entries; `bind_rows()` fills missing
#' columns with `NA` instead of erroring. The tibble class is stripped so
#' every `get_*()` function consistently returns a plain `data.frame`.
#'
#' @param results List of data.frames (or `NULL` entries, which are dropped).
#'
#' @return A plain `data.frame`.
#' @keywords internal
combine_file_results <- function(results) {
  results <- Filter(Negate(is.null), results)
  if (length(results) == 0L) {
    return(data.frame())
  }
  as.data.frame(dplyr::bind_rows(results))
}


#' Delete a file, retrying briefly if it is transiently locked
#'
#' On Windows, GDAL/antivirus can briefly hold a file handle open after
#' `$close()` returns, causing [fs::file_delete()] to fail with `[EBUSY]`
#' even though the file is otherwise unused. Retries a few times with a
#' short pause before giving up.
#'
#' @param path Character. Path to the file to delete.
#' @param attempts Integer. Number of attempts before giving up (default 3).
#' @param wait Numeric. Seconds to wait between attempts (default 0.2).
#'
#' @return Logical, invisibly: `TRUE` if the file was deleted (or already
#'   absent), `FALSE` if all attempts failed.
#' @keywords internal
delete_with_retry <- function(path, attempts = 3L, wait = 0.2) {
  if (!fs::file_exists(path)) {
    return(invisible(TRUE))
  }
  for (i in seq_len(attempts)) {
    ok <- !inherits(try(fs::file_delete(path), silent = TRUE), "try-error")
    if (ok) {
      return(invisible(TRUE))
    }
    if (i < attempts) Sys.sleep(wait)
  }
  invisible(FALSE)
}


#' Write a temporary VPC from LAS files, setting CRS if missing
#'
#' Internal wrapper around [lasR::write_vpc()] that checks whether the first
#' file has a valid CRS via [is_valid_crs()] and prepends [lasR::set_crs()] to
#' the pipeline if not.
#'
#' @param las_files Character vector of LAS/LAZ/COPC file paths.
#' @param epsg Integer. Fallback EPSG code applied when the file CRS is missing
#'   or unrecognised. Default is 25832.
#' @param use_gpstime Logical. Passed to [lasR::write_vpc()]. Default is `TRUE`.
#' @param absolute_path Logical. Passed to [lasR::write_vpc()]. Default is
#'   `TRUE`.
#'
#' @return Path to the temporary VPC file (invisibly, as returned by
#'   [lasR::exec()]).
#'
#' @keywords internal
exec_write_vpc <- function(las_files, epsg = 25832L, use_gpstime = TRUE, absolute_path = TRUE) {
  header <- lidR::readLASheader(las_files[1])
  crs <- sf::st_crs(header)$epsg
  write_stage <- lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path = absolute_path, use_gpstime = use_gpstime)
  pipeline <- if (!is_valid_crs(crs)) lasR::set_crs(epsg) + write_stage else write_stage
  lasR::exec(pipeline, on = las_files)
}


#' Null coalescing operator
#'
#' Returns `x` if not `NULL`, otherwise `y`.
#'
#' @name null-coalesce
#' @param x,y Any R objects.
#' @return `x` if non-`NULL`, otherwise `y`.
#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x


#' Offset between LAS-stored "Adjusted Standard GPS Time" and true GPS time
#'
#' Per the ASPRS LAS specification, files using Adjusted Standard GPS Time
#' store `GPS Time - 1,000,000,000`; this constant converts back.
#'
#' @keywords internal
LAS_ADJUSTED_GPSTIME_OFFSET <- 1e9


#' Parse a single processing-log JSON file into a data.frame of file entries
#'
#' @param log_file Character. Path to one `processing_log_*.json` file.
#'
#' @return A data.frame with columns `input`, `output`, `status`, `size_in`,
#'   `size_out`, or `NULL` if the log contains no file entries.
#' @keywords internal
read_log_file_entries <- function(log_file) {
  log <- tryCatch(yyjsonr::read_json_file(log_file), error = function(e) NULL)
  if (is.null(log) || is.null(log$files)) {
    return(NULL)
  }

  files_df <- if (is.data.frame(log$files)) {
    log$files
  } else {
    # fallback: coerce list of lists to data frame
    do.call(rbind, lapply(Filter(is.list, log$files), function(f) {
      data.frame(
        input = f$input %||% NA_character_,
        output = f$output %||% NA_character_,
        status = f$status %||% NA_character_,
        size_in = f$size_in %||% NA_integer_,
        size_out = f$size_out %||% NA_integer_,
        stringsAsFactors = FALSE
      )
    }))
  }

  if (is.null(files_df) || nrow(files_df) == 0L) {
    return(NULL)
  }

  # ensure expected columns exist even if a log predates one of them
  for (col in c("output", "size_in", "size_out")) {
    if (is.null(files_df[[col]])) files_df[[col]] <- NA
  }

  files_df
}


#' Read all JSON processing logs in a directory into one data.frame
#'
#' @param log_dir Character. Path to the directory containing JSON log files.
#'
#' @return A data.frame with columns `input`, `output`, `status`, `size_in`,
#'   `size_out` combining entries from every log file, or `NULL` if no logs
#'   exist or none contain file entries.
#' @keywords internal
read_log_entries <- function(log_dir) {
  log_files <- fs::dir_ls(log_dir, glob = "*.json", recurse = FALSE)
  if (length(log_files) == 0L) {
    return(NULL)
  }

  entries <- Filter(Negate(is.null), lapply(log_files, read_log_file_entries))
  if (length(entries) == 0L) {
    return(NULL)
  }

  do.call(rbind, entries)
}


#' Get successfully processed input paths from existing log files
#'
#' Reads all JSON processing logs in `log_dir` and returns the input file paths
#' that completed with a successful or skipped status. Used to avoid
#' reprocessing files on subsequent runs.
#'
#' @param log_dir Character. Path to the directory containing JSON log files.
#'
#' @return Character vector of normalised input file paths that were
#'   successfully processed. Returns `character(0)` if no logs exist or none
#'   contain successful entries.
#' @keywords internal
processed_inputs_from_logs <- function(log_dir) {
  log_entries <- read_log_entries(log_dir)
  if (is.null(log_entries)) {
    return(character(0))
  }

  success_statuses <- c("success", "success_with_warnings", "skipped_existing")
  paths <- log_entries$input[log_entries$status %in% success_statuses]

  unique(normalizePath(paths, winslash = "/", mustWork = FALSE))
}
