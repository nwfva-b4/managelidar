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
  crs <- lidR::epsg(header)
  write_stage <- lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path = absolute_path, use_gpstime = use_gpstime)
  pipeline <- if (!is_valid_crs(crs)) lasR::set_crs(epsg) + write_stage else write_stage
  lasR::exec(pipeline, on = las_files)
}
