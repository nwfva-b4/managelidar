#' Check file names
#'
#' Checks the file names according to [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111).
#' File names should be in the following schema:
#' `prefix`_`utmzone`_`minx`_`miny`_`tilesize`_`region`_`year``.laz`
#'
#' (e.g. `3dm_32_547_5724_1_ni_2024.laz`)
#'
#' @param path A path to a directory which contains las/laz files
#' @param prefix 3 letter character. Naming prefix (defaults to "3dm")
#' @param zone 2 digits integer. UTM zone (defaults to 32)
#' @param region 2 letter character. Region abbreviation (defaults to "ni")
#' @param year YYYY. (optional) acquisition year to append to filename. 
#' If not provided the year will be extracted from the files. It will be the acquisition date if points contain datetime in GPStime format, otherwise it will get the year from the file header, which is the processing date by definition.  
#' @param full.names Whether to return the full file path or just the file names (default)
#'
#' @return A dataframe with name_is, name_should, correct
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' check_names(f)
check_names <- function(path, prefix = "3dm", zone = 32, region = "ni", year = NULL, full.names = FALSE) {
  print("create VPC with GPStime")
  ans <- lasR::exec(
    lasR::set_crs(25832) + lasR::write_vpc(ofile = tempfile(fileext = ".vpc"), use_gpstime = TRUE, absolute_path = TRUE),
    with = list(ncores = lasR::concurrent_files(lasR::half_cores())),
    on = path
  )

  json <- jsonlite::fromJSON(ans)


  bbox <- json$features$properties$`proj:bbox`

  minx <- sapply(bbox, function(x) floor(round(x[1] / 1000, 2)))
  miny <- sapply(bbox, function(x) floor(round(x[2] / 1000, 2)))
  maxx <- sapply(bbox, function(x) floor(round(x[3] / 1000, 2)))

  tilesize <- maxx - minx


  if (is.null(year)) {
    # set year to acqusition /processing year
    year <- format(as.Date(json$features$properties$datetime), "%Y")
  }

  if (full.names == FALSE) {
    name_is <- basename(json$features$asset$data$href)
    name_should <- paste0(prefix, "_", zone, "_", minx, "_", miny, "_", tilesize, "_", region, "_", year, ".", tools::file_ext(json$features$asset$data$href))
  } else {
    name_is <- json$features$asset$data$href
    name_should <- file.path(dirname(name_is), paste0(prefix, "_", zone, "_", minx, "_", miny, "_", tilesize, "_", region, "_", year, ".", tools::file_ext(json$features$asset$data$href)))
  }


  dat <- data.frame(
    name_is = name_is,
    name_should = name_should,
    correct = name_is == name_should
  )

  return(dat)
}
