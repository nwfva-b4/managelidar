#' Map a function over LAS/LAZ/COPC files
#'
#' Internal helper to apply a function to multiple LASfiles, optionally using
#' parallel processing via mirai. Errors in individual files are caught and
#' returned as structured failure entries rather than propagating.
#'
#' @param files Character vector of LAS/LAZ/COPC file paths.
#' @param FUN Function to apply to each file.
#' @param workers Integer or `NULL`. Number of parallel workers.
#'   If `NULL` (default), workers are set to half of available logical cores
#'   when 20 or more files are detected, and sequential processing is used
#'   otherwise. Set to `1` to force sequential processing regardless of file
#'   count. Set to a positive integer to force that number of workers, up to
#'   the number of logical cores (100%). Requesting more than half of
#'   available cores triggers a warning, since each worker loads its own copy
#'   of the point cloud data and may exhaust available RAM.
#'
#' @return A list with one element per file. Failed files return a list with
#'   `output = NULL` and a `log` entry with `status = "failed"`.
#' @keywords internal
map_las <- function(files, FUN, workers = NULL) {
  n <- length(files)
  if (n == 0L) {
    return(list())
  }

  safe_FUN <- function(f) {
    tryCatch(FUN(f), error = function(e) {
      list(
        output = NULL,
        log = list(
          input  = normalizePath(f, winslash = "/", mustWork = FALSE),
          output = NA_character_,
          status = "failed",
          error  = conditionMessage(e)
        )
      )
    })
  }

  # Resolve number of workers

  n_cores <- parallel::detectCores(logical = TRUE)
  max_workers <- max(1L, n_cores) # hard cap: cannot exceed logical cores
  safe_workers <- max(1L, floor(n_cores / 2L)) # recommended default

  n_workers <- if (!is.null(workers)) {
    w <- as.integer(workers)
    if (w > safe_workers) {
      cli::cli_warn(
        "Requested {w} workers exceeds the recommended maximum ({safe_workers} = half of {n_cores} logical cores). Using more workers than this may exhaust available RAM, since each worker loads its own copy of the point cloud data."
      )
    }
    w
  } else if (n >= 20L) {
    safe_workers
  } else {
    1L
  }
  n_workers <- min(n_workers, n, max_workers)

  if (n_workers > 1L) {
    message("Processing ", n, " LASfiles in parallel (", n_workers, " workers)")
    mirai::daemons(
      n_workers,
      ..args = list(.expr = quote(library(managelidar)))
    )
    on.exit(mirai::daemons(0), add = TRUE)
    res <- mirai::mirai_map(files, safe_FUN)
    return(mirai::collect_mirai(res, c(".progress")))
  }

  lapply(files, safe_FUN)
}