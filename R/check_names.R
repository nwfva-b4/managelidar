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
#' f <- system.file("extdata", package = "managelidar")
#' check_names(f)
check_names <- function(path, prefix = "3dm", zone = 32, region = NULL, year = NULL, copc = FALSE, full.names = FALSE) {
  # ------------------------------------------------------------------
  # Resolve all LAS/LAZ/COPC files
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)
  if (length(files) == 0) stop("No LAS/LAZ/COPC files found.")


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

  json <- jsonlite::fromJSON(vpc_file)


  # ------------------------------------------------------------------
  # Compute tile bounding boxes
  # ------------------------------------------------------------------
  bbox <- json$features$properties$`proj:bbox`
  minx <- vapply(bbox, function(x) floor(round(x[1] / 1000, 2)), numeric(1))
  miny <- vapply(bbox, function(x) floor(round(x[2] / 1000, 2)), numeric(1))
  maxx <- vapply(bbox, function(x) floor(round(x[3] / 1000, 2)), numeric(1))
  maxy <- vapply(bbox, function(x) floor(round(x[4] / 1000, 2)), numeric(1))

  # take into account small inaccuracies (reduce tilesize if less than 50m larger)
  tilesize <- ceiling(pmax(maxx - minx, maxy - miny, 1) - 0.05)


  # ------------------------------------------------------------------
  # Determine region
  # ------------------------------------------------------------------
  # get region via extent if not provided
  if (is.null(region)) {
    # get region
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

    url <- "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/georef-germany-land/exports/parquet?lang=en&timezone=Europe%2FBerlin"
    states_sf <- arrow::read_parquet(file = url) |>
      sf::st_as_sf() |>
      sf::st_set_geometry("geo_shape") |>
      dplyr::mutate(code = state_codes[lan_name]) |>
      sf::st_set_crs(4326)

    extents <- json$features$bbox

    find_state_code <- function(bbox_coords, states_sf) {
      bbox <- sf::st_as_sfc(sf::st_bbox(c(xmin = bbox_coords[1], ymin = bbox_coords[2], xmax = bbox_coords[4], ymax = bbox_coords[5]), crs = 4326))

      sf::st_agr(states_sf) <- "constant"
      intersections <- sf::st_intersection(states_sf, bbox)
      intersections <- intersections |> dplyr::mutate(intersection_area = sf::st_area(geo_shape))

      state_code <- intersections |>
        dplyr::filter(intersection_area == max(intersection_area)) |>
        dplyr::pull(code)

      # set state code to "de" if no overlap with federal boundaries (e.g. at sea)
      if (rlang::is_empty(state_code)) {
        state_code <- "de"
      }


      return(state_code)
    }

    # Apply the function to each bbox
    region <- sapply(extents, find_state_code, states_sf = states_sf)
  }

  # ------------------------------------------------------------------
  # Determine year
  # ------------------------------------------------------------------
  # get year via VPC if not provided
  # in VPC it is extracted from first point if possible and from header (likely wrong) otherwise
  if (is.null(year)) {
    year <- format(as.Date(json$features$properties$datetime), "%Y")
  } else if (is.numeric(year)) {
    year <- as.character(year)
  } else if (is.character(year) && length(year) == 1 && file.exists(year)) {
    files_names <- managelidar::get_names(vpc_file, full.names = TRUE)
    year <- vapply(files_names, function(f) {
      managelidar::get_date(f, from_csv = year, return_referenceyear = TRUE)[["date"]]
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
