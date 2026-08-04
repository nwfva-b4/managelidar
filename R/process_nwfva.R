#' Process LiDAR data to standardized format using the NWFVA naming convention
#'
#' Convenience wrapper around [raw_to_processed()] that always uses
#' `standard = "nwfva"` with the ALS-pointcloud defaults (`platform = "als"`,
#' `product = "punktwolke"`), so callers processing NWFVA data don't need to
#' know about [raw_to_processed()]'s more general `standard`/`platform`/`product`
#' parameters. See [raw_to_processed()] for the full processing pipeline and
#' [check_names()] for the exact NWFVA filename schema.
#'
#' @param path Character. Path to LAS/LAZ/COPC file(s), directory, or VPC.
#' @param campaign Character. A single `surveyarea_contractor` label (e.g.
#'   `"solling_sgb4"`); cannot be derived from the data.
#' @param out_dir Character. Output root directory; outputs are nested under
#'   `{out_dir}/{region}/als/{year}/{campaign}/punktwolke/...`.
#' @param log_dir Character. Output directory where logfiles and data summaries
#'   will be saved.
#' @param region Character. Two-letter region code (federal states of Germany)
#'   for filename generation (e.g., "ni"). If `NULL` (default), region is
#'   automatically inferred from file bounding boxes.
#' @param from_csv Character. Path to CSV file containing acquisition dates used for
#'   year correction in filenames where data does not contain valid GPS time.
#' @param epsg Integer. EPSG code for the coordinate reference system.
#'   Default is 25832 (ETRS89 / UTM zone 32N).
#' @param workers Integer or `NULL`. Number of parallel workers. See
#'   [raw_to_processed()].
#' @param verbose Logical. Print progress messages. Default is TRUE.
#'
#' @return Invisibly returns a list of output file paths (NULL for failed files).
#'
#' @export
#'
#' @examples
#' \donttest{
#' folder <- system.file("extdata", package = "managelidar")
#' out_dir <- tempfile("processed_nwfva_")
#' process_nwfva(path = folder, campaign = "solling_sgb4", out_dir = out_dir, region = "ni")
#' }
process_nwfva <- function(path,
                           campaign,
                           out_dir = tempdir(),
                           log_dir = tempdir(),
                           region = NULL,
                           from_csv = NULL,
                           epsg = 25832L,
                           workers = NULL,
                           verbose = TRUE) {
  raw_to_processed(
    path = path,
    out_dir = out_dir,
    log_dir = log_dir,
    epsg = epsg,
    standard = "nwfva",
    region = region,
    from_csv = from_csv,
    campaign = campaign,
    platform = "als",
    product = "punktwolke",
    workers = workers,
    verbose = verbose
  )
}
