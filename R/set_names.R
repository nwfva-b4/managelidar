#' Set LASfile names according to a naming standard
#'
#' `set_names()` renames LAS/LAZ/COPC files to match either the
#' [ADV naming standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111)
#' or the NWFVA naming standard. See [check_names()] for the exact filename
#' schemas.
#'
#' @inheritParams check_names
#' @param dry_run Logical. If `TRUE`, only preview renaming without modifying files (default `FALSE`).
#' @param verbose Logical. Print messages and a preview of renaming (default `FALSE`).
#'
#' @return Invisibly returns a `data.frame` with columns `from` and `to` showing original and new filenames.
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' set_names(f, verbose = TRUE, dry_run = TRUE)
#'
#' set_names(f,
#'   standard = "nwfva", region = "ni", campaign = "solling_sgb4",
#'   dry_run = TRUE, verbose = TRUE
#' )
#'
#' @export
set_names <- function(path, standard = c("adv", "nwfva"), region = NULL, from_csv = NULL,
                       epsg = 25832L, product = NULL, copc = FALSE, campaign = NULL,
                       platform = "als", dry_run = FALSE, verbose = FALSE) {
  standard <- match.arg(standard)

  # ------------------------------------------------------------------
  # Check filenames
  # ------------------------------------------------------------------
  df <- check_names(path,
    standard = standard, region = region, from_csv = from_csv, epsg = epsg,
    product = product, copc = copc, campaign = campaign, platform = platform,
    full.names = TRUE
  )
  df <- subset(df, correct == FALSE)

  # rename columns for clarity
  df <- df |>
    dplyr::rename(from = name_is, to = name_should) |>
    dplyr::select(from, to)

  if (nrow(df) == 0L) {
    if (verbose) message("All filenames already match the expected naming convention.")
    return(invisible(df))
  }

  # ------------------------------------------------------------------
  # Print basenames only
  # ------------------------------------------------------------------
  if (verbose) {
    message("Files to be renamed (from \u2192 to):")
    print(data.frame(
      from = basename(df$from),
      to = basename(df$to),
      stringsAsFactors = FALSE
    ), row.names = FALSE)
  }

  # ------------------------------------------------------------------
  # Dry run check
  # ------------------------------------------------------------------
  if (dry_run) {
    if (verbose) message("Dry run enabled: no files were renamed.")
    return(invisible(df))
  }

  # ------------------------------------------------------------------
  # Perform actual renaming
  # ------------------------------------------------------------------
  success <- file.rename(from = df$from, to = df$to)
  if (!all(success)) {
    cli::cli_warn("Some files could not be renamed. Check permissions or file paths.")
  }

  message("Renaming complete: ", sum(success), " of ", nrow(df), " file(s) successfully renamed.")

  invisible(df)
}
