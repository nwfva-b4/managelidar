#' Create a Geopackage containing metadata of LASfiles
#'
#' `get_gpkg()` converts the metadata of a Virtual Point Cloud (.vpc) or a collection of LAS/LAZ/COPC
#' files into Geopackage. VPCs can be read and visualized by QGIS, however individual tiles (features) can not be queried as is.
#' To enable this we convert it to a Geopackage, which can be easily explored in any GIS.
#' Each LAS tile becomes a feature with its spatial extent and some metadata.
#'
#'
#' @param path Character. Path to a LAS/LAZ/COPC file, a directory containing LASfiles,
#'   or a Virtual Point Cloud (.vpc) file.
#' @param out_file Path to the output Geopackage (.gpkg) file (default: tempfile).
#' @param overwrite Logical. If TRUE, overwrite the output file if it exists (default: FALSE).
#' @param crs Integer. Optional EPSG code to reproject the VPC (default: 25832).
#' @param metrics Optional. Controls whether summary metrics are computed and
#'   added to the output layer.
#'   - `NULL` (default): no summary metrics are computed.
#'   - `TRUE`: compute the default set of metrics returned by `get_summary()`.
#'   - Character vector: compute only the specified metrics, e.g.
#'     `c("z_mean", "classification_mode", "intensity_mean")`.
#'
#'   Computing metrics requires reading the point data from all files and can
#'   substantially increase processing time. See `get_summary()` for available
#'   metrics and details.
#'
#' @return Invisibly returns an `sf` object representing the tiles written to the Geopackage.
#' @export
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#' las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")
#' las_files |> get_gpkg()
#'
get_gpkg <- function(path, out_file = tempfile(fileext = ".gpkg"), overwrite = FALSE, crs = 25832, metrics = NULL) {
  # ------------------------------------------------------------------
  # Resolve LASfiles and build VPC if not provided
  # ------------------------------------------------------------------
  vpc_file <- resolve_vpc(path, out_file = tempfile(fileext = ".vpc"))

  # Check if resolve_vpc returned NULL
  if (is.null(vpc_file)) {
    return(invisible(NULL))
  }

  # ------------------------------------------------------------------
  # Read VPC as sf
  # ------------------------------------------------------------------
  vpc_sf <- sf::st_read(vpc_file, quiet = TRUE)


  # ------------------------------------------------------------
  # Expand proj:bbox (list column → numeric columns)
  # ------------------------------------------------------------

  bbox_df <- as.data.frame(do.call(rbind, vpc_sf$`proj:bbox`))
  names(bbox_df) <- c("xmin", "ymin", "xmax", "ymax")

  vpc_sf <- dplyr::bind_cols(
    vpc_sf |> dplyr::select(-`proj:bbox`),
    bbox_df
  )

  # ------------------------------------------------------------------
  # Reproject if requested
  # ------------------------------------------------------------------
  if (!is.null(crs)) {
    vpc_sf <- sf::st_transform(vpc_sf, crs)
  }

  # ------------------------------------------------------------------
  # Optional: add summary metrics
  # ------------------------------------------------------------------
  if (!is.null(metrics)) {
    if (metrics == TRUE) {
      # use default metrcis
      summary <- get_summary(
        vpc_file,
        iwbin = 0,
        zwbin = 0
      )
    } else {
      # use custom metrics
      summary <- get_summary(
        vpc_file,
        iwbin = 0,
        zwbin = 0,
        metrics = metrics
      )
    }


    # Normalize names to match VPC id
    names(summary) <- fs::path_ext_remove(names(summary))

    # convert to data frame
    summary_df <- purrr::map_dfr(names(summary), function(id) {
      x <- summary[[id]]

      out <- data.frame(
        id = id,
        npoints = x$npoints,
        nsingle = x$nsingle,
        nwithheld = x$nwithheld,
        nsynthetic = x$nsynthetic,
        stringsAsFactors = FALSE
      )

      if (!is.null(x$metrics)) {
        out <- cbind(out, x$metrics)
      }

      out
    })

    vpc_sf <- dplyr::left_join(vpc_sf, summary_df, by = "id")


    # Convert temporal metrics t_* (GPS seconds) to POSIXct
    gps_epoch <- as.POSIXct("1980-01-06 00:00:00", tz = "UTC")

    vpc_sf <- vpc_sf |>
      dplyr::mutate(
        dplyr::across(
          dplyr::starts_with("t_"),
          ~ gps_epoch + .x + 1e9,
          .names = "{.col}"
        )
      )
  }


  # ------------------------------------------------------------------
  # Drop non-exportable / redundant columns
  # ------------------------------------------------------------------
  vpc_sf <- dplyr::select(
    vpc_sf,
    -dplyr::any_of(c("proj.wkt2"))
  )

  vpc_sf <- vpc_sf[, !sapply(vpc_sf, is.list)]


  # ------------------------------------------------------------------
  # Write Geopackage
  # ------------------------------------------------------------------
  if (tools::file_ext(out_file) == "") {
    out_file <- fs::path_ext_set(out_file, "gpkg")
  }

  if (file.exists(out_file) && !overwrite) {
    stop(
      "Output file already exists. Use overwrite = TRUE to replace it: ",
      out_file
    )
  }

  sf::st_write(vpc_sf, out_file, quiet = TRUE)
  message("Wrote Geopackage: ", out_file)

  invisible(vpc_sf)
}
