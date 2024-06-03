

#' Set file names
#'
#' Renames files according to schema validated by `check_files()`.
#'
#' @param path Path to folder containing laz files
#'
#' @return Renamed files
#' @export
#'
#' @examples
#' f <- system.file("extdata/3dm_32_547_5724_1_ni_20240327.laz", package="managelidar")
#' tmpname <- file.path(dirname(f), "wrongname.laz")
#' file.copy(f, tmpname)
#' set_names(tmpname)
#' file.remove(tmpname)
set_names <- function(path, prefix = "3dm", zone = 32, region = "ni", date = NULL){
  t <- managelidar::check_names(path, prefix, zone, region, date, full.names = T)
  t <- subset(t, correct_naming == FALSE)

  if(ncol(t) == 0L){
    stop("all names already as expected")
  }

  print(t)
  print(paste0("Renaming ", nrow(t), " files"))

  file.rename(from = t$name_is, to = t$name_should)
}
