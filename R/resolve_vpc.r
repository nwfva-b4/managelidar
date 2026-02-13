#' Resolve input paths to a single deduplicated VPC
#'
#' Takes a mix of LAS/LAZ/COPC files, `.vpc` files, and VPC objects already loaded in R,
#' merges them if needed, deduplicates tiles (based on storage location), and returns a
#' VPC object or file path.
#'
#' @param paths Character vector of input paths, or a list containing VPC objects.
#'   Can be a mix of file paths (strings) and VPC objects (lists with type="FeatureCollection").
#' @param out_file Optional. Path where the VPC should be saved. If NULL (default),
#'   returns the VPC as an R object. If provided, saves to file and returns the file path.
#'
#' @return If `out_file` is NULL, returns a list containing the VPC structure.
#'   If `out_file` is provided, returns the path to the saved `.vpc` file.
#'
#' @keywords internal
resolve_vpc <- function(paths, out_file = NULL) {
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
  file_paths <- unlist(paths[!is_vpc_object])

  # Normalize and expand file paths
  if (length(file_paths) > 0) {
    file_paths <- fs::path_norm(fs::path_expand(file_paths))
  }

  # Separate VPC files vs non-VPC files
  vpc_files <- character()
  non_vpc <- character()

  if (length(file_paths) > 0) {
    vpc_files <- file_paths[
      fs::file_exists(file_paths) &
        tolower(fs::path_ext(file_paths)) == "vpc"
    ]
    non_vpc <- setdiff(file_paths, vpc_files)
  }

  # Resolve LAS files
  las_files <- if (length(non_vpc) > 0) resolve_las_paths(non_vpc) else character()

  # Temporary list to hold all VPC files/objects for merging
  to_merge_files <- vpc_files
  to_merge_objects <- vpc_objects

  # ------------------------------------------------------------
  # If there are LAS files, create a temporary VPC
  # ------------------------------------------------------------
  if (length(las_files) > 0) {
    las_vpc <- lasR::exec(
      lasR::write_vpc(
        tempfile(fileext = ".vpc"),
        absolute_path = TRUE,
        use_gpstime = TRUE
      ),
      on = las_files
    )
    to_merge_files <- c(to_merge_files, las_vpc)
  }

  # ------------------------------------------------------------
  # Read all VPC files into objects
  # ------------------------------------------------------------
  if (length(to_merge_files) > 0) {
    vpc_objs_from_files <- lapply(to_merge_files, function(file) {
      tryCatch(
        yyjsonr::read_json_file(file),
        error = function(e) {
          warning("Could not read VPC file: ", file)
          return(NULL)
        }
      )
    })
    # Remove NULL entries from failed reads
    vpc_objs_from_files <- vpc_objs_from_files[!vapply(vpc_objs_from_files, is.null, logical(1))]
    to_merge_objects <- c(to_merge_objects, vpc_objs_from_files)
  }

  # ------------------------------------------------------------
  # Check if we have any valid VPC objects
  # ------------------------------------------------------------
  if (length(to_merge_objects) == 0) {
    warning("No valid VPC objects or LAS/LAZ/COPC files found")
    return(invisible(NULL))
  }

  # ------------------------------------------------------------
  # If only one VPC object, return it based on out_file
  # ------------------------------------------------------------
  if (length(to_merge_objects) == 1) {
    if (is.null(out_file)) {
      return(to_merge_objects[[1]])
    } else {
      jsonlite::write_json(to_merge_objects[[1]], out_file, pretty = TRUE, auto_unbox = TRUE)
      return(out_file)
    }
  }

  # ------------------------------------------------------------
  # Merge multiple VPCs
  # ------------------------------------------------------------

  # Internal helper for merging VPC objects
  merge_vpcs_objects <- function(vpc_objects) {
    all_features <- do.call(rbind, lapply(vpc_objects, function(vpc) {
      vpc$features
    }))

    all_features <- all_features |>
      dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
      dplyr::distinct(href, .keep_all = TRUE) |>
      dplyr::select(-href)

    list(
      type = "FeatureCollection",
      features = all_features
    )
  }

  merged_vpc <- merge_vpcs_objects(to_merge_objects)

  # Return based on out_file parameter
  if (is.null(out_file)) {
    return(merged_vpc)
  } else {
    jsonlite::write_json(merged_vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    return(out_file)
  }
}