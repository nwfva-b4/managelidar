#' Compute summary metrics for individual LAS files and optionally save as JSON
#'
#' `get_summary()` calculates standard summary metrics for LAS files, including:
#'
#' * Temporal metrics (`t_min`, `t_median`, `t_max`)
#' * Intensity metrics (`i_min`, `i_mean`, `i_median`, `i_max`, `i_p5`, `i_p95`, `i_sd`)
#' * Elevation metrics (`z_min`, `z_median`, `z_max`)
#' * Histograms (`i_histogram`, `z_histogram`) if `iwbin` and `zwbin` are greater than 0
#' * Point counts and classifications (`npoints`, `nsingle`, `nwithheld`, `nsynthetic`, `npoints_per_return`, `npoints_per_class`)
#' * Coordinate system (`epsg`)
#'
#' Results can optionally be saved as JSON files per LAS file.
#'
#' @param path Path to a LAS/LAZ/COPC file, a directory, or a Virtual Point Cloud (.vpc) file.
#' @param out_dir Optional directory to save JSON summaries. If not set, the function returns a named list instead.
#' @param full.names Logical. If `TRUE`, the returned list is named with full paths; otherwise, basenames are used.
#' @param samplebased Logical. If `TRUE`, reads only a spatial subsample of each file (faster for large files).
#' @param zwbin Numeric. Bin width (meters) for elevation histogram (`z_histogram`). Set `0` to skip `z_histogram`.
#' @param iwbin Numeric. Bin width (intensity units) for intensity histogram (`i_histogram`). Set `0` to skip `i_histogram`.
#' @param metrics Character vector of metrics to compute. Defaults to:
#'   \code{c("t_min", "t_median", "t_max", "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd", "z_min", "z_median", "z_max")}.
#'
#' @details
#' In comparison to `lasR::summarise` this function returns individual summaries per file instead of an aggregated summary among all files.
#' If `out_dir` is provided, a JSON file is created for each LAS file, with the same
#' name but `.json` extension. Existing JSON files are skipped automatically. If `out_dir`
#' is not provided, the function returns a named list where each element corresponds to a LAS file.
#'
#' Setting `iwbin = 0` or `zwbin = 0` disables calculation of intensity or elevation histograms,
#' which can save time and memory for large datasets.
#'
#' Parallel processing is used automatically for large numbers of files through `map_las()`.
#'
#' @return If `out_dir` is not set, returns a named list, one element per LAS file. Each element is a list containing:
#' \describe{
#'   \item{npoints}{Total number of points}
#'   \item{nsingle}{Number of single-return points}
#'   \item{nwithheld}{Number of withheld points}
#'   \item{nsynthetic}{Number of synthetic points}
#'   \item{npoints_per_return}{Named vector of counts per return number}
#'   \item{npoints_per_class}{Named vector of counts per classification code}
#'   \item{z_histogram}{Elevation histogram (if `zwbin > 0`)}
#'   \item{i_histogram}{Intensity histogram (if `iwbin > 0`)}
#'   \item{epsg}{EPSG code of the LAS file CRS}
#'   \item{metrics}{List of calculated summary metrics, e.g., min, median, max for time, intensity, and elevation}
#' }
#'
#' If `out_dir` is set, the function returns `NULL` invisibly after writing JSON files.
#'
#' @export
get_summary <- function(
  path,
  out_dir = NULL,
  full.names = FALSE,
  samplebased = FALSE,
  zwbin = 10,
  iwbin = 100,
  metrics = c(
    "t_min", "t_median", "t_max",
    "i_min", "i_mean", "i_median", "i_max",
    "i_p5", "i_p95", "i_sd",
    "z_min", "z_median", "z_max"
  )
) {
  # -------------------------------
  # Resolve all LAS files
  # -------------------------------
  las_files <- resolve_las_paths(path)

  if (length(las_files) == 0) {
    message("No LAS/LAZ/COPC files found.")
    return(invisible(list()))
  }

  # -------------------------------
  # Skip already processed files if out_dir is set
  # -------------------------------
  if (!is.null(out_dir)) {
    fs::dir_create(out_dir, recurse = TRUE)
    json_files <- fs::path(out_dir, fs::path_file(fs::path_ext_set(las_files, "json")))
    keep <- !file.exists(json_files)
    n_skipped <- sum(!keep)
    if (n_skipped > 0) message("Skipping ", n_skipped, " already processed files")
    las_files <- las_files[keep]
  }

  if (length(las_files) == 0) {
    message("Nothing to process.")
    return(invisible(list()))
  }

  # -------------------------------
  # Worker function for a single file
  # -------------------------------
  get_summary_per_file <- function(file) {
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
        pipeline <- reader + lasR::summarise(zwbin = zwbin, iwbin = iwbin, metrics = metrics)
        ans <- lasR::exec(pipeline, on = file, with = list(ncores = 1))

        # ---- Cleanup ----
        ans$crs <- NULL
        ans <- lapply(ans, function(x) if (is.atomic(x) && !is.null(names(x))) as.list(x) else x)

        # ---- Write JSON ----
        if (!is.null(out_dir)) {
          file_out <- fs::path(out_dir, fs::path_file(fs::path_ext_set(file, "json")))
          jsonlite::write_json(ans, file_out, pretty = TRUE, auto_unbox = TRUE)
          return(invisible(NULL))
        }

        # ---- Return ----
        filename <- if (full.names) file else basename(file)
        out <- list(ans)
        names(out) <- filename
        out
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
  res <- map_las(las_files, get_summary_per_file)

  # Flatten one level so filenames are top-level keys
  res <- unlist(res, recursive = FALSE)

  res
}
