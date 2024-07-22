#' Set file names
#'
#' Renames files according to schema validated by `check_files()`. This is according to [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111).
#'
#' @param path A path to a directory which contains las/laz files
#' @param prefix 3 letter character. Naming prefix (defaults to "3dm")
#' @param zone 2 digits integer. UTM zone (defaults to 32)
#' @param region 2 letter character. (optional) federal state abbreviation. It will be fetched automatically if Null.
#' @param year YYYY. (optional) acquisition year to append to filename.
#' If not provided the year will be extracted from the files. It will be the acquisition date if points contain datetime in GPStime format, otherwise it will get the year from the file header, which is the processing date by definition.
#'
#' @return Renamed files
#' @export
#'
#' @examples
#' f <- system.file("extdata/3dm_32_547_5724_1_ni_20240327.laz", package = "managelidar")
#' copy <- tempfile(fileext = ".laz")
#' file.copy(f, copy)
#' set_names(copy)
set_names <- function(path, prefix = "3dm", zone = 32, region = NULL, year = NULL) {
  t <- managelidar::check_names(path, prefix, zone, region, year, full.names = T)
  t <- subset(t, correct == FALSE)

  if (ncol(t) == 0L) {
    stop("all names already as expected")
  }

  print(paste0("Renaming ", nrow(t), " files"))

  file.rename(from = t$name_is, to = t$name_should)
}
