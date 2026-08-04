#' Resolve shared naming components from a VPC
#'
#' Computes the CRS/zone, grid-snapped spatial extent, region, and year for
#' every feature in a VPC - the data needed by both the AdV and NWFVA
#' filename builders ([adv_filename()], [nwfva_filename()]). Standard-agnostic:
#' the two builders differ only in how they assemble these components into a
#' filename string.
#'
#' @param vpc A VPC object as returned by [resolve_vpc()].
#' @param region Optional character vector of two-letter region codes. If
#'   `NULL`, the region is automatically inferred from file bounding boxes via
#'   [detect_region()].
#' @param from_csv Optional path to CSV file for year determination.
#' @param epsg Integer. EPSG code used as fallback CRS when a file does not
#'   contain a valid CRS.
#'
#' @return A list with `files`, `zone`, `minx`/`miny`/`maxx`/`maxy`,
#'   `tilesize`, `region`, `year`, `date_source`, `ext_suffix` - one value per
#'   file (recycled for scalar inputs like an explicit `region`).
#' @keywords internal
resolve_naming_components <- function(vpc, region = NULL, from_csv = NULL, epsg = 25832L) {
  files <- sapply(vpc$features$assets, function(x) x$data$href)

  # ------------------------------------------------------------------
  # Get CRS and calculate zone
  # ------------------------------------------------------------------
  crs_data <- get_crs(vpc, full.names = TRUE)

  # Fall back to epsg parameter if CRS is missing or invalid
  effective_crs <- if (is_valid_crs(crs_data$crs[1])) crs_data$crs[1] else epsg

  # Calculate zone from EPSG (last 2 digits)
  # Assumes UTM zones like EPSG:25832 -> zone 32
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
    region <- detect_region(ext, effective_crs)
  }

  # ------------------------------------------------------------------
  # Determine year
  # ------------------------------------------------------------------
  temporal_data <- get_temporal_extent(
    vpc,
    per_file = TRUE,
    full.names = TRUE,
    from_csv = from_csv,
    return_referenceyear = TRUE,
    fix_false_gpstime = TRUE,
    epsg = epsg,
    verbose = FALSE
  )

  # Match years to files
  year <- temporal_data$date[match(files, temporal_data$filename)]
  year <- as.character(year)
  date_source <- temporal_data$date_source[match(files, temporal_data$filename)]

  list(
    files = files,
    zone = zone,
    minx = minx, miny = miny, maxx = maxx, maxy = maxy,
    tilesize = tilesize,
    region = region,
    year = year,
    date_source = date_source,
    ext_suffix = tools::file_ext(files)
  )
}


#' Auto-detect region (German federal state) from tile centroids
#'
#' Downloads (and caches for the session via `options(managelidar.states_sf=)`)
#' German federal state boundaries, then intersects each tile's centroid
#' against them to find its two-letter state code.
#'
#' @param ext data.frame with per-file spatial extent columns `xmin`/`xmax`/
#'   `ymin`/`ymax`, as returned by [get_spatial_extent()].
#' @param effective_crs Integer EPSG code the extent coordinates are expressed in.
#'
#' @return Character vector of two-letter region codes (`"de"` where no state matches).
#' @keywords internal
detect_region <- function(ext, effective_crs) {
  ## OPT: cache states per session
  states_sf <- getOption("managelidar.states_sf")
  if (is.null(states_sf)) {
    state_codes <- c(
      "Baden-W\u00fcrttemberg" = "bw",
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
      "Th\u00fcringen" = "th"
    )

    states_sf <- tryCatch(
      arrow::read_parquet(
        "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/georef-germany-land/exports/parquet?lang=en&timezone=Europe%2FBerlin"
      ) |>
        sf::st_as_sf() |>
        sf::st_set_geometry("geo_shape") |>
        dplyr::mutate(code = state_codes[lan_name]) |>
        sf::st_set_crs(4326),
      error = function(e) {
        cli::cli_abort(
          "Could not download federal state boundaries for automatic region detection. Pass {.arg region} explicitly, or check your network connection.",
          parent = e
        )
      }
    )

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

  ifelse(is.na(state_match$code), "de", state_match$code)
}


#' Assemble a filename following the German AdV standard
#'
#' Pure filename assembly (no I/O): `product_zone_minx_miny_tilesize_region_year.ext`.
#'
#' @param product Character. Data-product token (AdV calls this a "prefix", e.g. `"3dm"`).
#' @param zone,minx,miny,tilesize,region,year Components as returned by [resolve_naming_components()].
#' @param ext Character. File extension (without leading dot).
#' @param copc Logical. Whether to insert a `.copc` suffix before the extension.
#'
#' @return Character vector of assembled filenames.
#' @keywords internal
adv_filename <- function(product, zone, minx, miny, tilesize, region, year, ext, copc = FALSE) {
  optional_copc <- if (copc) ".copc" else ""
  paste0(
    product, "_", zone, "_",
    minx, "_", miny, "_",
    tilesize, "_", region, "_",
    year, optional_copc, ".", ext
  )
}


#' Assemble a filename following the NWFVA standard
#'
#' Pure filename assembly (no I/O): `region_platform_year_campaign_product_x_y.ext`.
#'
#' @param region Character. Two-letter region code.
#' @param platform Character. Platform token (e.g. `"als"`).
#' @param year Character. Acquisition year.
#' @param campaign Character. `surveyarea_contractor` campaign label.
#' @param product Character. Data-product token (e.g. `"punktwolke"`).
#' @param x,y Numeric. Lower-left tile corner coordinates, in full meters,
#'   snapped to the 1000m tile grid (i.e. `minx`/`miny` from
#'   [resolve_naming_components()] multiplied by 1000).
#' @param ext Character. File extension (without leading dot).
#'
#' @return Character vector of assembled filenames.
#' @keywords internal
nwfva_filename <- function(region, platform, year, campaign, product, x, y, ext) {
  # as.integer() avoids paste0()/as.character() silently switching to
  # scientific notation for round coordinates (e.g. 600000 -> "6e+05",
  # since that's shorter than "600000" and R's default scipen has no bias)
  paste0(region, "_", platform, "_", year, "_", campaign, "_", product, "_", as.integer(x), "_", as.integer(y), ".", ext)
}


#' Resolve the NWFVA output directory for a given output kind
#'
#' NWFVA organises outputs under `{root}/{region}/{platform}/{year}/{campaign}/{product}/...`,
#' branching into `daten/` for point clouds, `doku/vpc/` for VPC metadata, and
#' `doku/overview/` for overview images.
#'
#' @param root Character. Root output directory (e.g. `raw_to_processed()`'s `out_dir`).
#' @param region,platform,year,campaign,product Character. Path components.
#' @param kind One of `"pointcloud"`, `"vpc"`, `"overview"`.
#'
#' @return Character scalar path (not yet created on disk).
#' @keywords internal
nwfva_output_dir <- function(root, region, platform, year, campaign, product,
                              kind = c("pointcloud", "vpc", "overview")) {
  kind <- match.arg(kind)
  sub_dir <- switch(kind,
    pointcloud = "daten",
    vpc = fs::path("doku", "vpc"),
    overview = fs::path("doku", "overview")
  )
  fs::path(root, region, platform, year, campaign, product, sub_dir)
}


#' Remove now-empty directories along a path, stopping at (not including) `stop_at`
#'
#' NWFVA's per-file directory nesting (`region/platform/year/campaign/product/...`)
#' can leave an empty subtree behind: the initial guess of `year` (from
#' first-point or header GPS time) may later be corrected from the median
#' GPS time once the point cloud is actually read, or a file's outputs may be
#' rolled back entirely after a failure - either way the directories created
#' for that attempt are never populated. This walks upward from `path`,
#' deleting each directory only while it is currently empty, so genuinely
#' populated directories (this file's own successful output, or another
#' concurrent worker's) are never touched.
#'
#' @param path Character. Leaf directory to start pruning from.
#' @param stop_at Character. Ancestor directory to stop at (never removed,
#'   even if empty - typically the shared `region/platform` level).
#'
#' @return `NULL`, invisibly. Best-effort: any failure to delete (e.g. a
#'   concurrent worker populated the directory between the emptiness check
#'   and the delete) simply stops the walk early.
#' @keywords internal
prune_empty_dirs <- function(path, stop_at) {
  if (!fs::dir_exists(path)) {
    return(invisible(NULL))
  }
  path <- fs::path_norm(fs::path_abs(path))
  stop_at <- fs::path_norm(fs::path_abs(stop_at))

  while (nchar(path) > nchar(stop_at) && startsWith(path, stop_at) && fs::dir_exists(path)) {
    if (length(fs::dir_ls(path, all = TRUE)) > 0) break
    ok <- !inherits(try(fs::dir_delete(path), silent = TRUE), "try-error")
    if (!ok) break
    path <- fs::path_dir(path)
  }
  invisible(NULL)
}
