#' Write a temporary VPC from LAS files, setting CRS if missing
#'
#' Internal wrapper around `lasR::write_vpc` that checks whether the first
#' file has a valid CRS and prepends `lasR::set_crs` to the pipeline if not.
#'
#' @param las_files Character vector of LAS/LAZ/COPC file paths.
#' @param epsg Integer. Fallback EPSG code when CRS is missing. Default is 25832.
#' @param use_gpstime Logical. Passed to `lasR::write_vpc`. Default is TRUE.
#'
#' @return Path to the temporary VPC file.
#'
#' @keywords internal
exec_write_vpc <- function(las_files, epsg = 25832L, use_gpstime = TRUE, absolute_path = TRUE) {
  header <- lidR::readLASheader(las_files[1])
  crs <- lidR::epsg(header)
  write_stage <- lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path = absolute_path, use_gpstime = use_gpstime)
  pipeline <- if (crs == 0L) lasR::set_crs(epsg) + write_stage else write_stage
  lasR::exec(pipeline, on = las_files)
}
