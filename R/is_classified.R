#' Check whether LASfiles are classified
#'
#' `is_classified()` determines whether LAS point cloud files contain
#' point classifications other than class `0` (unclassified).
#'
#' Unlike header-based functions, this function reads actual point data.
#' To reduce I/O overhead, only a *subset* of points is sampled:
#'
#' * For LAS/LAZ files, points are sampled from a small circular region (10m radius)
#'   around the spatial center of the file.
#' * For COPC files, only the first two hierarchy levels (0,1) are read.
#'
#' As a result, classification status is inferred from the sampled points
#' and may not reflect the full contents of the file. To determine if a LASfile is
#' classified this is usually sufficient, but to get class abundances consider using
#' \code{\link{get_summary}}.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing
#'   such files, or a Virtual Point Cloud (`.vpc`).
#' @param samplebased Logical. If `TRUE` (default), reads only a spatial subsample of each file.
#' @param full.names Logical. If `TRUE`, return full file paths; otherwise
#'   return base filenames only (default).
#' @param add_classes Logical. If `TRUE`, include a list-column with the
#'   detected classification codes present in the sampled points.
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{file}{Filename of the LASfile.}
#'   \item{classified}{Logical indicating whether classified points
#'   (class > 0) are present.}
#'   \item{classes}{(Optional) List column of detected class codes.}
#' }
#'
#' @seealso \code{\link{get_summary}}
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' las_files |> is_classified(add_classes = TRUE)
#'
is_classified <- function(path, samplebased = TRUE, full.names = FALSE, add_classes = FALSE) {
  # -------------------------------
  # Resolve all LASfiles
  # -------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # -------------------------------
  # Worker function for a single file
  # -------------------------------
  is_classified_per_file <- function(file) {
    tryCatch(
      {
        # ---- Reader selection ----
        reader <- if (samplebased) {
          if (endsWith(file, ".copc.laz")) {
            lasR::reader(copc_depth = 1)
          } else {
            header <- lidR::readLASheader(file)
            xc <- (header$`Min X` + header$`Max X`) / 2
            yc <- (header$`Min Y` + header$`Max Y`) / 2
            lasR::reader_circles(xc, yc, 10)
          }
        } else {
          lasR::reader()
        }

        # ---- lasR pipeline ----
        pipeline <- reader + lasR::summarise()
        ans <- lasR::exec(pipeline, on = file, with = list(ncores = 1))

        # check if all points are 0
        classified <- !(all(names(ans$npoints_per_class) == "0") && length(names(ans$npoints_per_class)) == 1)

        # adjust filenames
        if (!full.names) file <- basename(file)

        if (add_classes) {
          data.frame(
            file = file,
            classified = classified,
            classes = I(list(as.integer(names(ans$npoints_per_class))))
          )
        } else {
          data.frame(
            file = file,
            classified = classified
          )
        }
      },
      error = function(e) {
        filename <- if (full.names) file else basename(file)
        message("ERROR processing ", filename, ": ", conditionMessage(e))
        out <- list(list(error = conditionMessage(e)))
        names(out) <- filename
        out
      }
    )
  }

  # -------------------------------
  # Map over files
  # -------------------------------
  data.table::rbindlist(map_las(files, is_classified_per_file))
}
