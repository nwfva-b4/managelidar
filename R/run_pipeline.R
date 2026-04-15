#' Execute lasR pipeline on catalog
#'
#' Wrapper for \code{lasR::exec()} that works seamlessly in VPC-pipelines and handles
#' VPC objects. Automatically writes VPC objects to temporary files as needed by lasR.
#'
#' @param path Character or list. Path(s) to LAS/LAZ/COPC files, a directory, a VPC file,
#'   or a VPC object already loaded in R.
#' @param pipeline A lasR pipeline object created with lasR functions.
#' @param ... Additional arguments passed to \code{lasR::exec()}.
#'
#' @return Result from \code{lasR::exec()}, typically a list with pipeline outputs.
#'
#' @details
#' This function enables pipeline-style workflows with lasR by:
#' \itemize{
#'   \item Accepting the data source as the first argument (pipe-friendly)
#'   \item Handling VPC objects directly (writes to temp file automatically)
#'   \item Working with any input type accepted by \code{resolve_vpc()}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' folder |>
#'   filter_temporal("2024") |>
#'   run_pipeline(lasR::dsm())
run_pipeline <- function(path, pipeline, ...) {
  # Check if path is a single .vpc file on disk
  is_vpc_file <- length(path) == 1 &&
    is.character(path) &&
    fs::is_file(path) &&
    tolower(fs::path_ext(path)) == "vpc"

  # If already a VPC file, use it directly
  if (is_vpc_file) {
    lasR::exec(pipeline = pipeline, on = path, ...)
  } else {
    # Otherwise, resolve to a temp VPC file
    vpc_file <- resolve_vpc(path, out_file = tempfile(fileext = ".vpc"))
    lasR::exec(pipeline = pipeline, on = vpc_file, ...)
  }
}
