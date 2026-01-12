#' Map a function over LAS/LAZ/COPC files
#'
#' Internal helper to apply a function to multiple LAS files,
#' using parallel processing (mirai) only when beneficial.
#'
#' @param files Character vector of LAS/LAZ/COPC file paths.
#' @param FUN Function to apply to each file.
#'
#' @return A list with one element per file.
#' @keywords internal
map_las <- function(files, FUN) {
  n <- length(files)

  if (n == 0L) {
    return(list())
  }

  # use parallel only if worthwhile
  if (n >= 20L) {
    cores <- parallel::detectCores(logical = TRUE)
    workers <- max(1L, floor(cores / 2L))
    workers <- min(workers, n)

    message(
      "Processing ", n, " LAS files in parallel (",
      workers, " workers)"
    )

    mirai::daemons(workers)
    on.exit(mirai::daemons(0), add = TRUE)

    res <- mirai::mirai_map(
      files,
      FUN
    )

    return(mirai::collect_mirai(res, c(".progress")))
  }

  # fallback: sequential
  lapply(files, FUN)
}
