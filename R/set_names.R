#' Set LASfile names according to ADV standard
#'
#' `set_names()` renames LAS/LAZ/COPC files to match the [ADV naming standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111).
#'
#' Files are expected to follow the schema:
#' `prefix_utmzone_minx_miny_tilesize_region_year.laz`
#'
#' @param path Character. Path to a LAS/LAZ/COPC file or a directory containing LASfiles.
#' @param prefix Character. Naming prefix (default `"3dm"`).
#' @param zone Integer. UTM zone (default `32`).
#' @param region Character. Federal state abbreviation (optional). Automatically determined if `NULL`.
#' @param year Integer or character. Acquisition year to append to filenames (optional). If `NULL`, the year is derived from the file.
#' @param copc Logical. Whether files are COPC (`.copc.laz`, default `FALSE`).
#' @param verbose Logical. Print messages and a preview of renaming (default `FALSE`).
#' @param dry_run Logical. If `TRUE`, only preview renaming without modifying files (default `FALSE`).
#'
#' @return Invisibly returns a `data.frame` with columns `from` and `to` showing original and new filenames.
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' set_names(copy, verbose = TRUE, dry_run = TRUE)
#'
#' @export
set_names <- function(path, prefix = "3dm", zone = 32, region = NULL, year = NULL, copc = FALSE, dry_run = FALSE) {
  # ------------------------------------------------------------------
  # Check filenames
  # ------------------------------------------------------------------
  df <- check_names(path, prefix, zone, region, year, copc, full.names = TRUE)
  df <- subset(df, correct == FALSE)

  # rename columns for clarity
  df <- df |>
    dplyr::rename(from = name_is, to = name_should) |>
    dplyr::select(from, to)

  if (nrow(df) == 0L) {
    message("All filenames already match the expected naming convention.")
    return(invisible(df))
  }

  # ------------------------------------------------------------------
  # Print basenames only
  # ------------------------------------------------------------------
  message("Files to be renamed (from → to):")
  print(data.frame(
    from = basename(df$from),
    to = basename(df$to),
    stringsAsFactors = FALSE
  ), row.names = FALSE)

  # ------------------------------------------------------------------
  # Dry run check
  # ------------------------------------------------------------------
  if (dry_run) {
    message("Dry run enabled: no files were renamed.")
    return(invisible(df))
  }

  # ------------------------------------------------------------------
  # Perform actual renaming
  # ------------------------------------------------------------------
  success <- file.rename(from = df$from, to = df$to)
  if (!all(success)) {
    warning("Some files could not be renamed. Check permissions or file paths.")
  }

  message("Renaming complete: ", sum(success), " of ", nrow(df), " file(s) successfully renamed.")

  invisible(df)
}
