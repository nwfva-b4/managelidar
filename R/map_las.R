#' Map a function over LAS/LAZ/COPC files
#'
#' Internal helper to apply a function to multiple LASfiles,
#' using parallel processing (mirai) if applied on at least 20 files.
#' Errors in individual files are caught and returned as structured failure
#' entries rather than propagating.
#'
#' @param files Character vector of LAS/LAZ/COPC file paths.
#' @param FUN Function to apply to each file.
#'
#' @return A list with one element per file. Failed files return a list with
#'   `output = NULL` and a `log` entry with `status = "failed"`.
#' @keywords internal
map_las <- function(files, FUN) {
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

  if (n >= 20L) {
    cores <- parallel::detectCores(logical = TRUE)
    workers <- max(1L, floor(cores / 2L))
    workers <- min(workers, n)
    message("Processing ", n, " LASfiles in parallel (", workers, " workers)")
    mirai::daemons(
      workers,
      dispatcher = "process",
      ..args = list(.expr = quote(library(managelidar)))
    )
    on.exit(mirai::daemons(0), add = TRUE)
    res <- mirai::mirai_map(files, safe_FUN)
    return(mirai::collect_mirai(res, c(".progress")))
  }

  lapply(files, safe_FUN)
}
