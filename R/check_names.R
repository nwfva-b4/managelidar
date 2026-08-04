#' Validate LASfile names according to a naming standard
#'
#' `check_names()` verifies whether LAS/LAZ/COPC file names conform to either
#' the German AdV standard or the NWFVA standard for tiled LiDAR data.
#'
#' AdV file names follow the schema:
#' \code{product_utmzone_minx_miny_tilesize_region_year.laz}.
#' Example: \code{3dm_32_547_5724_1_ni_2024.laz}.
#' See the [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111) for details.
#'
#' NWFVA file names follow the schema:
#' \code{region_platform_year_campaign_product_x_y.laz}.
#' Example: \code{ni_als_2024_solling_sgb4_punktwolke_550000_5730000.laz}, where
#' `x`/`y` are the lower-left corner of the containing standard 1000x1000m
#' tile (full meters, grid-snapped) and `campaign` is a manually supplied
#' `surveyarea_contractor` label.
#'
#' @param path Character vector. Paths to LAS/LAZ/COPC files, directories
#'   containing such files, or a VPC object already loaded in R.
#' @param standard Character. Naming standard to check against: `"adv"`
#'   (default) or `"nwfva"`.
#' @param region Optional character vector of two-letter region codes. If
#'   `NULL`, the region is automatically inferred from file bounding boxes.
#' @param from_csv Optional path to CSV file for year determination. If provided,
#'   used to match acquisition dates for tiles without GPStime.
#' @param epsg Integer. EPSG code used as fallback CRS when a file does not
#'   contain a valid CRS. Default is 25832 (ETRS89 / UTM zone 32N).
#' @param full.names Logical. If `TRUE`, returns full file paths in `name_is`
#'   and `name_should`; otherwise, only the base file names.
#' @param product Character. Data-product token embedded in the filename
#'   (the AdV standard calls this a "prefix"). Defaults to `"3dm"` for
#'   `standard = "adv"` and `"punktwolke"` for `standard = "nwfva"`.
#' @param copc Logical. Whether the files are expected to be COPC (`.copc.laz`).
#'   Only relevant for `standard = "adv"`.
#' @param campaign Character. Required when `standard = "nwfva"`: a single
#'   `surveyarea_contractor` label (e.g. `"solling_sgb4"`); cannot be derived
#'   from the data.
#' @param platform Character. Platform token, only used for `standard =
#'   "nwfva"` (default `"als"`).
#'
#' @return A `data.frame` with one row per file and columns:
#' \describe{
#'   \item{name_is}{Existing file name or path}
#'   \item{name_should}{Expected file name according to the chosen standard}
#'   \item{correct}{Logical indicating whether the existing name matches the standard}
#'   \item{date_source}{How the date (year) was extracted}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")
#'
#' las_files |> check_names()
#'
#' las_files |> check_names(standard = "nwfva", region = "ni", campaign = "solling_sgb4")
check_names <- function(path, standard = c("adv", "nwfva"), region = NULL, from_csv = NULL,
                         epsg = 25832L, full.names = FALSE, product = NULL, copc = FALSE,
                         campaign = NULL, platform = "als") {
  standard <- match.arg(standard)

  if (standard == "nwfva" && is.null(campaign)) {
    cli::cli_abort(
      "{.arg campaign} must be supplied when {.code standard = \"nwfva\"} (e.g. {.val solling_sgb4})."
    )
  }

  product <- product %||% if (standard == "adv") "3dm" else "punktwolke"

  # ------------------------------------------------------------------
  # Build VPC once and reuse it
  # ------------------------------------------------------------------
  vpc <- resolve_vpc(path, out_file = NULL)

  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  if (nrow(vpc$features) == 0) {
    cli::cli_warn("No features in VPC")
    return(invisible(NULL))
  }

  comp <- resolve_naming_components(vpc, region = region, from_csv = from_csv, epsg = epsg)

  # ------------------------------------------------------------------
  # Construct expected file names
  # ------------------------------------------------------------------
  name_should <- if (standard == "adv") {
    adv_filename(
      product, comp$zone, comp$minx, comp$miny, comp$tilesize,
      comp$region, comp$year, comp$ext_suffix, copc = copc
    )
  } else {
    nwfva_filename(
      comp$region, platform, comp$year, campaign, product,
      comp$minx * 1000L, comp$miny * 1000L, comp$ext_suffix
    )
  }

  name_is <- if (full.names) comp$files else basename(comp$files)
  if (full.names) name_should <- fs::path(fs::path_dir(comp$files), name_should)

  # ------------------------------------------------------------------
  # Build result
  # ------------------------------------------------------------------
  data.frame(
    name_is = name_is,
    name_should = name_should,
    correct = name_is == name_should,
    date_source = comp$date_source,
    stringsAsFactors = FALSE
  )
}
