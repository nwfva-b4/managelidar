#' Resolve LAS/LAZ/COPC input paths
#'
#' Resolves a character vector of file system paths or VPC objects into a flat
#' character vector of LAS/LAZ/COPC file paths. Inputs may be individual files,
#' directories, `.vpc` files, or VPC objects already loaded in R. Unsupported
#' paths and formats are silently ignored.
#'
#' This function is intended for internal use. It performs no validation
#' beyond basic existence checks and never errors or warns.
#'
#' @param paths Character vector of file or directory paths, or a list that may
#'   contain VPC objects (lists with `type = "FeatureCollection"`).
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
#'   \item VPC objects already loaded in R (lists with `type = "FeatureCollection"`)
#' }
#'
#' Unsupported file formats, non-existent paths, empty directories,
#' and unreadable `.vpc` files are silently skipped.
#'
#' @keywords internal
resolve_las_paths <- function(paths) {
  # If paths is itself a VPC object, wrap it in a list
  if (is.list(paths) && !is.null(paths$type) && paths$type == "FeatureCollection") {
    paths <- list(paths)
  }

  # Separate VPC objects from file paths
  is_vpc_object <- vapply(paths, function(x) {
    if (!is.list(x)) {
      return(FALSE)
    }
    if (is.null(x$type)) {
      return(FALSE)
    }
    if (length(x$type) != 1) {
      return(FALSE)
    }
    return(x$type == "FeatureCollection")
  }, logical(1))

  vpc_objects <- paths[is_vpc_object]
  file_paths <- paths[!is_vpc_object]

  # Extract LAS files from VPC objects
  las_from_objects <- character()
  if (length(vpc_objects) > 0) {
    las_from_objects <- unlist(lapply(vpc_objects, function(vpc) {
      vapply(
        vpc$features$assets,
        function(x) x$data$href,
        character(1)
      )
    }), use.names = FALSE)
  }

  # Normalize and expand file paths
  if (length(file_paths) > 0) {
    file_paths <- fs::path_norm(fs::path_expand(unlist(file_paths)))
  }

  # Process file paths
  las_from_files <- unlist(lapply(file_paths, function(path) {
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

  # Combine and deduplicate
  las_files <- unique(c(las_from_objects, las_from_files))

  if (length(las_files) == 0) {
    return(invisible(character()))
  }
  las_files
}
