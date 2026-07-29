#' Check whether LASfiles are spatially indexed
#'
#' `is_indexed()` whether LASfiles are spatially indexed (either via external `.lax` file or internally)
#'
#' The input may be a single file, a directory containing LASfiles, or a
#' Virtual Point Cloud (`.vpc`) referencing LAS/LAZ/COPC files. Internally,
#' file paths are resolved using `resolve_las_paths()`.
#'
#' @param path Character. Path(s) to a LAS/LAZ/COPC file, a directory containing
#'   such files, or a Virtual Point Cloud (`.vpc`).
#' @param full.names Logical. If `TRUE`, return full file paths; otherwise
#'   return base filenames only (default).
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{file}{Filename of the LASfile.}
#'   \item{is_indexed}{Logical indicating whether point cloud is spatially indexed}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")
#'
#' las_files |> is_indexed()
#'
is_indexed <- function(path, full.names = FALSE) {
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    cli::cli_warn("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # lasR has no public equivalent as of the pinned lasR version (checked via
  # getNamespaceExports("lasR")); if a future lasR release renames/removes
  # this internal, surface an actionable error instead of "could not find
  # function". TODO: re-check getNamespaceExports("lasR") on lasR upgrades
  # and switch to a public API if one becomes available.
  indexed <- tryCatch(
    lasR:::is_indexed(files),
    error = function(e) {
      cli::cli_abort(
        "is_indexed() relies on an internal lasR function that changed in your installed lasR ({utils::packageVersion('lasR')}). Please file an issue at the managelidar repo.",
        parent = e
      )
    }
  )

  # adjust filenames
  if (!full.names) files <- basename(files)

  data.frame(filename = files, indexed)
}
