#' Resolve LAS/LAZ/COPC input paths
#'
#' Resolves a character vector of file system paths into a flat character
#' vector of LAS/LAZ/COPC file paths. Inputs may be individual files,
#' directories, or `.vpc` files. Unsupported paths and formats are silently
#' ignored.
#'
#' This function is intended for internal use. It performs no validation
#' beyond basic existence checks and never errors or warns.
#'
#' @param paths Character vector of file or directory paths.
#'
#' @return A character vector of resolved LAS/LAZ/COPC file paths.
#'   Returns an empty character vector (invisibly) if no valid files
#'   are found.
#'
#' @details
#' Supported inputs:
#' \itemize{
#'   \item Individual `.las`, `.laz`, or `.copc` files
#'   \item Directories (non-recursive search)
#'   \item `.vpc` files (assets are extracted from the VPC JSON)
#' }
#'
#' Unsupported file formats, non-existent paths, empty directories,
#' and unreadable `.vpc` files are silently skipped.
#'
#' @keywords internal
resolve_las_paths <- function(paths) {
  paths <- fs::path_norm(fs::path_expand(paths))

  las_files <- unlist(lapply(paths, function(path) {
    if (fs::file_exists(path) && !fs::dir_exists(path)) {
      ext <- tolower(fs::path_ext(path))

      if (ext == "vpc") {
        vpc <- tryCatch(
          yyjsonr::read_json_file(path),
          error = function(e) {
            return(NULL)
          }
        )

        if (is.null(vpc)) {
          return(character())
        }

        return(vapply(
          vpc$features$assets,
          function(x) x$data$href,
          character(1)
        ))
      }

      if (ext %in% c("las", "laz", "copc")) {
        return(path)
      }

      return(character())
    }

    if (fs::dir_exists(path)) {
      return(fs::dir_ls(
        path,
        recurse = FALSE,
        type = "file",
        regexp = "(?i)\\.(las|laz|copc)$",
        fail = FALSE
      ))
    }

    character()
  }), use.names = FALSE)

  las_files <- unique(las_files)

  if (length(las_files) == 0) {
    return(invisible(character()))
  }

  las_files
}
