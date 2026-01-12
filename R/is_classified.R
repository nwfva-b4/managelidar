#' Check whether LAS files are classified
#'
#' `is_classified()` determines whether LAS point cloud files contain
#' point classifications other than class `0` (unclassified).
#'
#' Unlike header-based functions, this function reads actual point data.
#' To reduce I/O overhead, only a *subset* of points is sampled:
#'
#' * For LAS/LAZ files, points are sampled from a small circular region
#'   around the spatial center of the file.
#' * For COPC files, only the first hierarchy level is read.
#'
#' As a result, classification status is inferred from the sampled points
#' and may not reflect the full contents of the file.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing
#'   such files, or a Virtual Point Cloud (`.vpc`).
#' @param full.names Logical. If `TRUE`, return full file paths; otherwise
#'   return base filenames only (default).
#' @param add_classes Logical. If `TRUE`, include a list-column with the
#'   detected classification codes present in the sampled points.
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{file}{Filename of the LAS file.}
#'   \item{classified}{Logical indicating whether classified points
#'   (class > 0) are present.}
#'   \item{classes}{(Optional) List column of detected class codes.}
#' }
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' is_classified(f)
#' is_classified(f, add_classes = TRUE)
#'
is_classified <- function(path, full.names = FALSE, add_classes = FALSE) {

  is_classified_per_file <- function(file) {

    if (endsWith(file, ".copc.laz")) {
      # read first hierachies if COPC
      ans <- lasR::exec(
        lasR::reader(copc_depth = 1) + lasR::summarise(),
        on = file)
    } else if (endsWith(file, ".las") || endsWith(file, ".laz")) {
      # read sample subset in center if las/laz
      header <- lidR::readLASheader(file)
      xc <- header$`Min X` + (header$`Max X` - header$`Min X`) / 2
      yc <- header$`Min Y` + (header$`Max Y` - header$`Min Y`) / 2
      ans <- lasR::exec(
        lasR::reader_circles(xc, yc, 10) + lasR::summarise(),
        on = file)
    }

    # check if all points are 0
    classified <- !(all(names(ans$npoints_per_class) == "0") && length(names(ans$npoints_per_class)) == 1)

    # adjust filenames
    if (!full.names) file <- basename(file)

    if (add_classes) {
      data.frame(file = file,
                 classified = classified,
                 classes = I(list(as.character(names(ans$npoints_per_class))))
                 )
    } else {
      data.frame(file = file,
                 classified = classified
                 )
    }
    }


  # ------------------------------------------------------------------
  # apply function
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    stop("No LAS/LAZ/COPC files found.")
  }

  data.table::rbindlist(map_las(files, is_classified_per_file))
}
