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
  crs <- lidR::wkt(header)
  write_stage <- lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path = absolute_path, use_gpstime = use_gpstime)
  pipeline <- if (!is_valid_crs(crs)) lasR::set_crs(epsg) + write_stage else write_stage
  lasR::exec(pipeline, on = las_files)
}


#' Null coalescing operator
#'
#' Returns `x` if not `NULL`, otherwise `y`.
#'
#' @param x,y Any R objects.
#' @return `x` if non-`NULL`, otherwise `y`.
#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x


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
  log_files <- fs::dir_ls(log_dir, glob = "*.json", recurse = FALSE)
  if (length(log_files) == 0L) {
    return(character(0))
  }

  success_statuses <- c("success", "success_with_warnings", "skipped_existing")

  paths <- unlist(lapply(log_files, function(lf) {
    log <- tryCatch(yyjsonr::read_json_file(lf), error = function(e) NULL)
    if (is.null(log) || is.null(log$files)) {
      return(character(0))
    }

    files_df <- if (is.data.frame(log$files)) {
      log$files
    } else {
      # fallback: coerce list of lists to data frame
      do.call(rbind, lapply(Filter(is.list, log$files), function(f) {
        data.frame(input = f$input %||% NA_character_, status = f$status %||% NA_character_, stringsAsFactors = FALSE)
      }))
    }

    if (is.null(files_df) || nrow(files_df) == 0L) {
      return(character(0))
    }

    files_df$input[files_df$status %in% success_statuses]
  }))

  unique(normalizePath(paths, winslash = "/", mustWork = FALSE))
}
