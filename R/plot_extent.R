#' Plot the spatial extent of LAS files
#'
#' `plot_extent()` visualizes the spatial extent of LAS/LAZ/COPC files on an
#' interactive map using bounding boxes derived from file headers or an
#' existing Virtual Point Cloud (VPC).
#'
#' @param path Character. Path(s) to LAS/LAZ/COPC files, a directory containing
#'   such files, or a Virtual Point Cloud (.vpc).
#'
#' @return An interactive `mapview` map displayed in the viewer.
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' plot_extent(f)
plot_extent <- function(path) {

  # ------------------------------------------------------------------
  # Resolve LAS files and build VPC if not provided
  # ------------------------------------------------------------------
  if (all(tools::file_ext(path) == "vpc") && length(path) == 1 && file.exists(path)) {
    vpc_file <- path
  } else {
    # resolve LAS/LAZ/COPC files
    files <- resolve_las_paths(path)
    if (length(files) == 0) stop("No LAS/LAZ/COPC files found.")

    # build temporary VPC for all files
    vpc_file <- lasR::exec(
      lasR::write_vpc(tempfile(fileext = ".vpc"), absolute_path = TRUE, use_gpstime = TRUE),
      on = files
    )
  }

  # ------------------------------------------------------------------
  # Read bbox info from VPC
  # ------------------------------------------------------------------
  vpc <- yyjsonr::read_json_file(vpc_file)

  ext <- data.frame(
    filename = sapply(vpc$features$assets, function(x) x$data$href),
    xmin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[1]),
    ymin = sapply(vpc$features$properties, function(x) x$`proj:bbox`[2]),
    xmax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[3]),
    ymax = sapply(vpc$features$properties, function(x) x$`proj:bbox`[4]),
    date = sapply(vpc$features$properties, function(x) x$`datetime`),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  ext <- sf::st_sf(ext, geometry = sf::st_read(vpc_file)$geometry) |>
    sf::st_zm()

  # adjust filenames
  if (!full.names) ext$filename <- basename(ext$filename)

  if (nrow(ext) == 0) {
    stop("No LAS/LAZ/COPC files found.")
  }

  # ------------------------------------------------------------------
  # Plot
  # ------------------------------------------------------------------
  mapview::mapviewOptions(basemaps = "OpenTopoMap")

  mapview::mapview(
    ext,
    alpha.regions = 0,
    label = "filename"
  )
}
