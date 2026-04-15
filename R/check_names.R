#' Validate LASfile names according to the ADV standard
#'
#' `check_names()` verifies whether LAS/LAZ/COPC file names conform to the
#' German AdV standard for tiled LiDAR data. File names are expected to
#' follow the schema: \code{prefix_utmzone_minx_miny_tilesize_region_year.laz}.
#' Example: \code{3dm_32_547_5724_1_ni_2024.laz}.
#' See the [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111) for details.
#'
#'
#' @param path Character vector. Paths to LAS/LAZ/COPC files, directories
#'   containing such files, or a VPC object already loaded in R.
#' @param prefix Character scalar. Naming prefix (default: `"3dm"`).
#' @param region Optional character vector of two-letter region codes. If
#'   `NULL`, the region is automatically inferred from file bounding boxes.
#' @param from_csv Optional path to CSV file for year determination. If provided,
#'   used to match acquisition dates for tiles without GPStime.
#' @param copc Logical. Whether the files are expected to be COPC (`.copc.laz`).
#' @param full.names Logical. If `TRUE`, returns full file paths in `name_is`
#'   and `name_should`; otherwise, only the base file names.
#' @param epsg Integer. EPSG code used as fallback CRS when a file does not
#'   contain a valid CRS. Default is 25832 (ETRS89 / UTM zone 32N).
#'
#' @return A `data.frame` with one row per file and columns:
#' \describe{
#'   \item{name_is}{Existing file name or path}
#'   \item{name_should}{Expected file name according to AdV standard}
#'   \item{correct}{Logical indicating whether the existing name matches the standard}
#' }
#'
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = TRUE, pattern = "*20240327.laz")
#'
#' las_files |> check_names()
check_names <- function(path, prefix = "3dm", region = NULL, from_csv = NULL,
                        copc = FALSE, full.names = FALSE, epsg = 25832L) {
  # ------------------------------------------------------------------
  # Build VPC once and reuse it
  # ------------------------------------------------------------------
  vpc <- resolve_vpc(path, out_file = NULL)

  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  if (nrow(vpc$features) == 0) {
    warning("No features in VPC")
    return(invisible(NULL))
  }

  files <- sapply(vpc$features$assets, function(x) x$data$href)

  # ------------------------------------------------------------------
  # Get CRS and calculate zone
  # ------------------------------------------------------------------
  crs_data <- get_crs(vpc, full.names = TRUE)

  # Fall back to epsg parameter if CRS is missing or invalid
  effective_crs <- if (is.na(crs_data$crs[1]) || crs_data$crs[1] == 0) epsg else crs_data$crs[1]

  # Calculate zone from EPSG (last 2 digits)
  # Assumes UTM zones like EPSG:25832 → zone 32
  zone <- effective_crs %% 100

  # ------------------------------------------------------------------
  # Get spatial extent
  # ------------------------------------------------------------------
  ext <- get_spatial_extent(vpc, per_file = TRUE, full.names = TRUE, verbose = FALSE)

  # ------------------------------------------------------------------
  # Compute tile coordinates with snapping
  # ------------------------------------------------------------------
  max_error <- 10 # meters tolerance for snapping

  minx <- floor((ext$xmin + max_error) / 1000)
  miny <- floor((ext$ymin + max_error) / 1000)
  maxx <- ceiling((ext$xmax - max_error) / 1000)
  maxy <- ceiling((ext$ymax - max_error) / 1000)

  tilesize_x <- maxx - minx
  tilesize_y <- maxy - miny
  tilesize <- pmax(tilesize_x, tilesize_y)

  # ------------------------------------------------------------------
  # Determine region
  # ------------------------------------------------------------------
  if (is.null(region)) {
    ## OPT: cache states per session
    states_sf <- getOption("managelidar.states_sf")
    if (is.null(states_sf)) {
      state_codes <- c(
        "Baden-Württemberg" = "bw",
        "Bayern" = "by",
        "Berlin" = "be",
        "Brandenburg" = "bb",
        "Bremen" = "hb",
        "Hamburg" = "hh",
        "Hessen" = "he",
        "Mecklenburg-Vorpommern" = "mv",
        "Niedersachsen" = "ni",
        "Nordrhein-Westfalen" = "nw",
        "Rheinland-Pfalz" = "rp",
        "Saarland" = "sl",
        "Sachsen" = "sn",
        "Sachsen-Anhalt" = "st",
        "Schleswig-Holstein" = "sh",
        "Thüringen" = "th"
      )

      states_sf <- arrow::read_parquet(
        "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/georef-germany-land/exports/parquet?lang=en&timezone=Europe%2FBerlin"
      ) |>
        sf::st_as_sf() |>
        sf::st_set_geometry("geo_shape") |>
        dplyr::mutate(code = state_codes[lan_name]) |>
        sf::st_set_crs(4326)

      options(managelidar.states_sf = states_sf)
    }

    sf::st_agr(states_sf) <- "constant"

    # Create points from tile centers for region lookup
    tile_centers <- sf::st_as_sf(
      data.frame(
        x = (ext$xmin + ext$xmax) / 2,
        y = (ext$ymin + ext$ymax) / 2
      ),
      coords = c("x", "y"),
      crs = effective_crs
    ) |>
      sf::st_transform(4326)

    # Find which state each tile center falls in
    state_match <- sf::st_join(tile_centers, states_sf, join = sf::st_within)

    region <- ifelse(is.na(state_match$code), "de", state_match$code)
  }

  # ------------------------------------------------------------------
  # Determine year
  # ------------------------------------------------------------------
  # Use get_temporal_extent with VPC to get years
  temporal_data <- get_temporal_extent(
    vpc,
    per_file = TRUE,
    full.names = TRUE,
    from_csv = from_csv,
    return_referenceyear = TRUE,
    fix_false_gpstime = TRUE,
    verbose = FALSE
  )

  # Match years to files
  year <- temporal_data$date[match(files, temporal_data$filename)]
  year <- as.character(year)

  # ------------------------------------------------------------------
  # Optional COPC suffix
  # ------------------------------------------------------------------
  optional_copc <- if (copc) ".copc" else ""

  # ------------------------------------------------------------------
  # Construct expected file names
  # ------------------------------------------------------------------
  ext_suffix <- tools::file_ext(files)
  name_should <- paste0(
    prefix, "_", zone, "_",
    minx, "_", miny, "_",
    tilesize, "_", region, "_",
    year, optional_copc, ".", ext_suffix
  )

  name_is <- if (full.names) files else basename(files)
  if (full.names) name_should <- fs::path(fs::path_dir(files), name_should)

  # ------------------------------------------------------------------
  # Build result
  # ------------------------------------------------------------------
  data.frame(
    name_is = name_is,
    name_should = name_should,
    correct = name_is == name_should,
    stringsAsFactors = FALSE
  )
}