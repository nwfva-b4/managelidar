#' Merge multiple Virtual Point Cloud (VPC) files
#'
#' `merge_vpcs()` reads one or more `.vpc` files, merges their features,
#' and removes duplicate tiles (based on storage location). Optionally, the merged
#' VPC can be written to a file.
#'
#' @param vpc_files Character. Paths to one or more `.vpc` files.
#' @param out_file Optional. Path to write the merged `.vpc` file. If `NULL`,
#'   a temporary file is created.
#' @param overwrite Logical. If `TRUE`, overwrite the output file if it exists.
#'
#' @return A list representing the merged VPC (STAC FeatureCollection).
#'   Invisibly returns the merged VPC. If `out_file` is provided, the file
#'   is written as a valid `.vpc` JSON.
#'
#' @examples
#' # Merge two VPC files
#' merged <- merge_vpcs(c("vpc1.vpc", "vpc2.vpc"))
#'
#' @export
merge_vpcs <- function(vpc_files, out_file = NULL, overwrite = FALSE) {
  if (length(vpc_files) == 0) stop("No VPC files provided.")
  vpc_files <- fs::path_norm(vpc_files)

  # ------------------------------------------------------------------
  # Read all VPC files
  # ------------------------------------------------------------------
  vpcs <- lapply(vpc_files, function(f) {
    if (!file.exists(f)) stop("VPC file not found: ", f)
    yyjsonr::read_json_file(f)
  })

  # ------------------------------------------------------------------
  # Extract features
  # ------------------------------------------------------------------
  features_list <- lapply(vpcs, `[[`, "features")

  features_df <- do.call(dplyr::bind_rows, features_list)

  # De-duplicate features by 'href' (filepath)
  features_df <- features_df |>
    dplyr::mutate(href = sapply(assets, function(x) x$data$href[1])) |>
    dplyr::distinct(href, .keep_all = TRUE) |>
    dplyr::select(-href)

  # ------------------------------------------------------------------
  # Rebuild merged VPC
  # ------------------------------------------------------------------
  merged_vpc <- vpcs[[1]]
  merged_vpc$features <- features_df

  # ------------------------------------------------------------------
  # Optionally write to file
  # ------------------------------------------------------------------
  if (!is.null(out_file)) {
    if (file.exists(out_file) && !overwrite) {
      stop("Output file exists: ", out_file)
    }
    jsonlite::write_json(merged_vpc, out_file, pretty = TRUE, auto_unbox = TRUE)
    message("Wrote merged VPC: ", out_file)
  }

  invisible(merged_vpc)
}
