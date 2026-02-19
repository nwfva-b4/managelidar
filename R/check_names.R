#' Validate LAS file names according to the ADV standard
#'
#' `check_names()` verifies whether LAS/LAZ/COPC file names conform to the
#' German AdV standard for tiled LiDAR data. File names are expected to
#' follow the schema: \code{prefix_utmzone_minx_miny_tilesize_region_year.laz}.
#' Example: \code{3dm_32_547_5724_1_ni_2024.laz}.
#' See the [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111) for details.
#'
#'
#' @param path Character vector. Paths to LAS/LAZ/COPC files or directories
#'   containing such files.
#' @param prefix Character scalar. Naming prefix (default: `"3dm"`).
#' @param zone Integer scalar. UTM zone (default: `32`).
#' @param region Optional character vector of two-letter region codes. If
#'   `NULL`, the region is automatically inferred from file bounding boxes.
#' @param year Optional acquisition year (`YYYY`) or path to CSV file.
#'   If `NULL`, the year is derived from the LAS header or GPStime metadata.
#' @param copc Logical. Whether the files are expected to be COPC (`.copc.laz`).
#' @param full.names Logical. If `TRUE`, returns full file paths in `name_is`
#'   and `name_should`; otherwise, only the base file names.
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
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#'
#' las_files |> check_names()
check_names <- function(path, prefix = "3dm", zone = 32, region = NULL, year = NULL, copc = FALSE, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Resolve all LAS/LAZ/COPC files
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # ------------------------------------------------------------------
  # Build a temporary VPC to extract metadata (bbox + datetime)
  # ------------------------------------------------------------------
  vpc_file <- lasR::exec(
    lasR::set_crs(25832) +
      lasR::write_vpc(
        ofile = tempfile(fileext = ".vpc"),
        use_gpstime = TRUE,
        absolute_path = TRUE
      ),
    with = list(ncores = lasR::concurrent_files(lasR::half_cores())),
    on = files
  )

  vpc <- yyjsonr::read_json_file(vpc_file)


  # ------------------------------------------------------------------
  # Compute tile bounding boxes
  # ------------------------------------------------------------------
  bbox <- vpc$features$properties$`proj:bbox`

  # small tile boundary offsets are ignored and extent is snapped to closest km-value
  max_error <- 10
  minx <- floor(vapply(bbox, function(x) (x[1] + max_error) / 1000, numeric(1)))
  miny <- floor(vapply(bbox, function(x) (x[2] + max_error) / 1000, numeric(1)))
  maxx <- ceiling(vapply(bbox, function(x) (x[3] - max_error) / 1000, numeric(1)))
  maxy <- ceiling(vapply(bbox, function(x) (x[4] - max_error) / 1000, numeric(1)))

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

    # ------------------------------------------------------------------
    # Build tile bounding boxes as sf polygons
    # ------------------------------------------------------------------
    tile_geoms <- lapply(vpc$features$bbox, function(b) {
      sf::st_as_sfc(
        sf::st_bbox(
          c(
            xmin = b[1],
            ymin = b[2],
            xmax = b[4],
            ymax = b[5]
          ),
          crs = 4326
        )
      )[[1]] # extract sfg from sfc
    })

    tile_sf <- sf::st_sf(
      tile_id = seq_along(tile_geoms),
      geometry = sf::st_sfc(tile_geoms, crs = 4326)
    )

    # ------------------------------------------------------------------
    # Intersect tiles with states
    # ------------------------------------------------------------------
    intersections <- suppressWarnings(
      sf::st_intersection(tile_sf, states_sf)
    )

    if (nrow(intersections) > 0) {
      intersections$area <- sf::st_area(intersections)

      region_map <- intersections |>
        dplyr::group_by(tile_id) |>
        dplyr::slice_max(area, n = 1, with_ties = FALSE) |>
        dplyr::ungroup() |>
        dplyr::select(tile_id, code)

      # default region = "de" (offshore / no overlap)
      region <- rep("de", nrow(tile_sf))
      region[region_map$tile_id] <- region_map$code
    } else {
      region <- rep("de", nrow(tile_sf))
    }
  }


  # ------------------------------------------------------------------
  # Determine year
  # ------------------------------------------------------------------
  # get year via VPC if not provided
  # in VPC it is extracted from first point if possible and from header (likely wrong) otherwise
  if (is.null(year)) {
    year <- format(as.Date(vpc$features$properties$datetime), "%Y")
  } else if (is.numeric(year)) {
    year <- as.character(year)
  } else if (is.character(year) && length(year) == 1 && file.exists(year)) {
    files_names <- managelidar::get_names(vpc_file, full.names = TRUE)
    year <- vapply(files_names, function(f) {
      managelidar::get_temporal_extent(f, from_csv = year, return_referenceyear = TRUE, verbose = FALSE)[["date"]]
    }, character(1))
  } else {
    year <- rep("1900", length(files))
  }

  # ------------------------------------------------------------------
  # Optional COPC suffix
  # ------------------------------------------------------------------
  optional_copc <- if (copc) ".copc" else ""

  # ------------------------------------------------------------------
  # Construct expected file names
  # ------------------------------------------------------------------
  ext <- tools::file_ext(files)
  name_should <- paste0(
    prefix, "_", zone, "_",
    minx, "_", miny, "_",
    tilesize, "_", region, "_",
    year, optional_copc, ".", ext
  )

  name_is <- if (full.names) files else basename(files)
  if (full.names) name_should <- file.path(dirname(files), name_should)

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
