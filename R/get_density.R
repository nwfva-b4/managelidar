#' Get approximate point and pulse density of LAS files
#'
#' `get_density()` calculates the approximate average point and pulse density of LAS files.
#'
#' Only the LAS file headers are read. Densities are calculated based on the bounding box
#' and number of points / first-return pulses. This does not account for missing data
#' within the bounding box, so the density is approximate and faster to compute than reading
#' the full point cloud.
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LAS files,
#'   or a Virtual Point Cloud (.vpc) referencing these files.
#' @param full.names Logical. If `TRUE`, filenames in the output are full paths; otherwise base filenames (default).
#'
#' @return A `data.frame` with columns:
#' \describe{
#'   \item{filename}{File name or path.}
#'   \item{npoints}{Total number of points in the file.}
#'   \item{npulses}{Number of first-return pulses.}
#'   \item{area}{Area of bounding box (units of CRS^2).}
#'   \item{pointdensity}{Approximate points per unit area.}
#'   \item{pulsedensity}{Approximate first-return pulses per unit area.}
#' }
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_density(f)
get_density <- function(path, full.names = FALSE) {
  get_density_per_file <- function(file) {
    header <- lidR::readLASheader(file)

    minx <- header$`Min X`
    miny <- header$`Min Y`
    maxx <- header$`Max X`
    maxy <- header$`Max Y`

    points <- header$`Number of point records`
    pulses <- header$`Number of points by return`[1]

    bbox <- sf::st_bbox(c(xmin = minx, xmax = maxx, ymax = maxy, ymin = miny), crs = sf::st_crs(header))
    area <- sf::st_area(sf::st_as_sfc(bbox))

    pointdensity <- points / area
    pulsedensity <- pulses / area

    # adjust filenames
    if (!full.names) file <- basename(file)

    data.frame(
      filename = file,
      npoints = points,
      npulses = pulses,
      area = as.numeric(area),
      pointdensity = as.numeric(pointdensity),
      pulsedensity = as.numeric(pulsedensity),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }

  # ------------------------------------------------------------------
  # apply function
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    stop("No LAS/LAZ/COPC files found.")
  }

  data.table::rbindlist(map_las(files, get_density_per_file))
}
