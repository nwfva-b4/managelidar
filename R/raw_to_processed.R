#' Process LiDAR data to standardized format
#'
#' Converts incoming ALS data to quality-controlled, standardized point clouds with
#' comprehensive metadata and overview images.
#'
#' @param path Character. Path to LAS/LAZ/COPC file(s), directory, or VPC.
#' @param out_dir Character. Output directory where processed files and metadata
#'   will be saved.
#' @param epsg Integer. EPSG code for the coordinate reference system.
#'   Default is 25832 (ETRS89 / UTM zone 32N).
#' @param region Character. Two-letter region code (federal states of Germany) for filename generation
#'   (e.g., "ni"). If NULL (default) region is automatically inferred from file bounding boxes.
#' @param from_csv Character. Path to CSV file containing acquisition dates used for
#'   year correction in filenames where data does not contain valid GPS time.
#' @param verbose Logical. Print progress messages. Default is TRUE.
#'
#' @return Invisibly returns a list of output file paths (NULL for failed files).
#'
#' @details
#' This function performs a comprehensive quality assurance pipeline:
#'
#' **Processing steps:**
#' \itemize{
#'   \item Generate AdV-compliant filenames
#'   \item Set CRS (if not present)
#'   \item Reclassify (AdV/LGLN to ASPRS scheme)
#'   \item Fix synthetic data (ReturnNumber, NumberOfReturns, GPStime)
#'   \item Filter erroneous data (ReturnNumber, NumberOfReturns, GPStime)
#'   \item Drop unused attributes
#'   \item Classify noise points
#'   \item Classify ground points
#'   \item Normalize intensity range
#'   \item Sort (optimize) point cloud
#'   \item Append spatial index
#'   \item Create overview image
#'   \item Create VPC file with additional metadata
#'   \item Create point cloud summaries
#'   \item Create log file
#' }
#'
#' **Output structure:**
#' The function creates the following directory structure in `out_dir` if not otherwise defined:
#' \describe{
#'   \item{`pointcloud/`}{Processed LAZ files with embedded spatial index}
#'   \item{`metadata/`}{Individual VPC files with additional metadata}
#'   \item{`overviews/`}{WEBP overview images (max elevation)}
#'   \item{`logfiles/`}{Processing logs with timing and status information}
#'   \item{`logfiles/summary_in`}{Data summaries of input LASfiles}
#'   \item{`logfiles/summary_out`}{Data summaries of output LASfiles}
#' }
#'
#' **Filename generation:**
#' Output files follow the German AdV naming convention:
#' `3dm_{zone}_{minx}_{miny}_{tilesize}_{region}_{year}.laz`
#'
#' The year is extracted from median GPS time to avoid errors from individual
#' erroneous points. Region can be specified or auto-detected from input filenames.
#'
#' **Performance:**
#' Processing runs in parallel (via mirai) when 20+ files are detected, using
#' half of available CPU cores. A comprehensive JSON log documents all processing
#' steps, timing, and any warnings or errors.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic usage with default settings
#' raw_to_processed(
#'   path = "raw_data/",
#'   out_dir = "processed/"
#' )
#' }
raw_to_processed <- function(path,
                             out_dir = tempdir(),
                             epsg = 25832L,
                             region = NULL,
                             from_csv = NULL,
                             verbose = TRUE) {
  # Initialize processing log
  processing_start <- Sys.time()

  # Helper function to create consistent file log entries
  create_file_log <- function(lasfile, pointcloud_file, status, file_start, warnings = character(0)) {
    list(
      input = normalizePath(lasfile, winslash = "/", mustWork = FALSE),
      output = normalizePath(pointcloud_file, winslash = "/", mustWork = FALSE),
      status = status,
      duration_seconds = round(as.numeric(difftime(Sys.time(), file_start, units = "secs")), 1),
      warnings = if (length(warnings) > 0) warnings else NULL
    )
  }

  # ------------------------------------------------------------------
  # Early filename determination using check_names
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }


  raw_to_processed_per_file <- function(lasfile) {
    file_start <- Sys.time()

    # Get original filename (for summary_original)
    original_filename <- fs::path_ext_remove(fs::path_file(lasfile))

    # Use check_names to get expected filename
    filenames <- check_names(lasfile, prefix = "3dm", region = NULL, from_csv = from_csv, epsg = epsg, full.names = TRUE)
    expected_filename <- fs::path_ext_remove(fs::path_file(filenames$name_should))

    # Define output file path
    pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(expected_filename, ".laz"))

    # Ckeck if processed file already exists, skip rest of pipeline in this case
    # in this early stage we can only check for filename based on date of first point, as this might be erroneous
    # in rare cases a second ckeck is done later after pointcloud data is read
    if (fs::file_exists(pointcloud_file)) {
      file_log <- create_file_log(lasfile, pointcloud_file, "skipped_existing", file_start)

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Already processed (skipped)")
      }
      return(list(output = pointcloud_file, log = file_log))
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # read pointcloud in memory
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    las_in_memory <- lasR::read_cloud(lasfile, progress = FALSE)

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # calculate summaries on original data
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    summarise_original <- lasR::summarise(
      zwbin = 50, iwbin = 100,
      metrics = c(
        "x_min", "x_max", "y_min", "y_max",
        "t_min", "t_median", "t_max",
        "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd",
        "z_min", "z_median", "z_max"
      )
    )
    summary_original <- lasR::exec(summarise_original, on = las_in_memory, with = list(progress = FALSE, ncores = 1))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # Update year in filename based on median GPS time
    # to overcome problems where gpstime of first point (used for date in VPC) is erroneous
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    generated_filename <- expected_filename
    warnings <- character(0)

    seconds_per_week <- 604800L

    # Try to get year from median GPS time
    if (!is.null(summary_original$metrics$t_median) &&
      summary_original$metrics$t_median > seconds_per_week) {
      # GPS time is seconds since 1980-01-06 00:00:00 UTC
      gps_epoch <- as.POSIXct("1980-01-06 00:00:00", tz = "UTC")
      date <- gps_epoch + summary_original$metrics$t_median + 1e9
      year_from_median <- format(date, "%Y")

      # Replace year in expected filename
      # Pattern: 3dm_32_547_5724_1_ni_YYYY.laz -> replace YYYY with year_from_median
      generated_filename <- sub(
        "_([0-9]{4})$",
        paste0("_", year_from_median),
        expected_filename
      )
    }

    # Update output file path with final filename
    pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(generated_filename, ".laz"))

    # Check again if file exists with updated filename (edge case where year changed)
    if (generated_filename != expected_filename && fs::file_exists(pointcloud_file)) {
      # Cleanup memory
      rm(las_in_memory)
      gc()

      file_log <- create_file_log(lasfile, pointcloud_file, "skipped_existing", file_start)

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Already processed (skipped)")
      }
      return(list(output = pointcloud_file, log = file_log))
    }


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # initialize pipeline with reading stage
    # this does nothing here as data is already read in memory, its only purpose is to initialize a pipeline we can add other stages to
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    pipeline <- lasR::reader()

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # set CRS
    # explicitly set the CRS if it is is not set or cannot properly be read (https://github.com/r-lidar/lasR/issues/265)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # EGSP 25832 is default for all cadastral data in western federal states of Germany
    set_crs <- lasR::set_crs(epsg)

    # set CRS if missing valid EPSG
    missing_crs <- summary_original$epsg == 0L

    if (missing_crs) {
      pipeline <- pipeline + set_crs
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # update classification
    # federal ALS data in Germany is classified in a different classification scheme than ASPRS
    # here we convert data to ASPRS standard (https://gist.github.com/wiesehahn/607930c73bb9472bb77e2e019b6a0be2)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    counts <- summary_original$npoints_per_class

    # check if data is LGLN legacy classification scheme
    # if class 13 is present in high proportions it represents likely Non-ground points, DSM-relevant (legacy LGLN) rather than Shield wire points (AdV and ASPRS)
    if (("13" %in% names(counts)) && ((counts["13"] / sum(counts)) > 0.01)) {
      pipeline <- pipeline +
        lasR::edit_attribute(filter = "Classification == 11", attribute = "Synthetic", value = TRUE) + # Synthetic water points -> Synthetic_flag
        lasR::edit_attribute(filter = "Classification == 8", attribute = "Classification", value = 9) + # 	Measured water points -> Water
        lasR::edit_attribute(filter = "Classification == 11", attribute = "Classification", value = 9) + # Synthetic water points -> Water
        lasR::edit_attribute(filter = "Classification == 12", attribute = "Classification", value = 20) + # Subsurface/basement points -> Ignored Ground
        lasR::edit_attribute(filter = "Classification == 13", attribute = "Classification", value = 1) + # Non-ground points, DSM-relevant -> Unclassified
        lasR::edit_attribute(filter = "Classification == 15", attribute = "Classification", value = 22) + # Other/unclassified points -> Temporal Exclusion
        lasR::edit_attribute(filter = "Classification %in% 20 22 23 25 26 27", attribute = "Classification", value = 12) + # Overlap points -> Overlap points
        lasR::edit_attribute(filter = "Classification > 27", attribute = "Classification", value = 1) # all other undefined classes -> Unclassified
    }

    # check if data is
    # if class 20 is present in high proportions it represents likely Non-ground points (AdV) rather than Ignored Ground points (ASPRS)
    else if (("20" %in% names(counts)) && ((counts["20"] / sum(counts)) > 0.1)) {
      pipeline <- pipeline +
        lasR::edit_attribute(filter = "Classification == 8", attribute = "Synthetic", value = TRUE) + # Synthetic water points -> Synthetic_flag
        lasR::edit_attribute(filter = "Classification == 8", attribute = "Classification", value = 9) + # Synthetic water points -> Water
        lasR::edit_attribute(filter = "Classification == 19", attribute = "Classification", value = 5) + # General vegetation -> High Vegetation (could be correctly assigned with HAG)
        lasR::edit_attribute(filter = "Classification == 20", attribute = "Classification", value = 1) + # Non-ground points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 21", attribute = "Classification", value = 2) + # Ground excluding basements -> Ground
        lasR::edit_attribute(filter = "Classification == 22", attribute = "Classification", value = 2) + # Verified ground points -> Ground
        lasR::edit_attribute(filter = "Classification == 23", attribute = "Classification", value = 1) + # Power infrastructure points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 24", attribute = "Classification", value = 20) + # Basement/light well points -> Ignored Groundc
        lasR::edit_attribute(filter = "Classification == 25", attribute = "Classification", value = 1) + # Hydraulic structure points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 26", attribute = "Classification", value = 1) + # Bridge foundation points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 27", attribute = "Classification", value = 6) + # General structure points -> Building
        lasR::edit_attribute(filter = "Classification == 28", attribute = "Classification", value = 6) + # Building installations -> Building
        lasR::edit_attribute(filter = "Classification == 29", attribute = "Synthetic", value = TRUE) + # Synthetic points -> Synthetic_flag
        lasR::edit_attribute(filter = "Classification == 29", attribute = "Classification", value = 1) + # Synthetic points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 30", attribute = "Synthetic", value = TRUE) + # Synthetic surface points -> Synthetic_flag
        lasR::edit_attribute(filter = "Classification == 30", attribute = "Classification", value = 1) + # Synthetic surface points -> Unclassified
        lasR::edit_attribute(filter = "Classification == 31", attribute = "Classification", value = 1) + # Filled points from ALS -> Unclassified
        lasR::edit_attribute(filter = "Classification > 31", attribute = "Classification", value = 1) # all other undefined classes -> Unclassified
    }
    # if classification scheme seems not AdV or legacy LGLN it is likely unclassified or ASPRS already
    else {
      pipeline <- pipeline +
        # in one campaign (Solling) high noise was classified as 64, cobersion should not affect other data
        lasR::edit_attribute(filter = "Classification == 64", attribute = "Classification", value = 18) + # high noise: 64 -> 18
        lasR::edit_attribute(filter = "Classification > 22", attribute = "Classification", value = 1) # all other undefined classes -> Unclassified
    }


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # fix synthetic data
    # it often shows no/erroneous information about ReturnNumber, NumberOfReturns, gpstime
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    pipeline <- pipeline +
      # set ReturnNumber and NumberOfReturns of invalid synthetic data
      lasR::edit_attribute(filter = c("Synthetic == 1", "NumberOfReturns == 0"), attribute = "NumberOfReturns", value = 1) +
      lasR::edit_attribute(filter = c("Synthetic == 1", "ReturnNumber == 0"), attribute = "ReturnNumber", value = 1) +
      # set gpstime of invalid synthetic data
      lasR::edit_attribute(filter = c("Synthetic == 1", paste("gpstime <=", seconds_per_week)), attribute = "gpstime", value = summary_original$metrics$t_median)


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # filter erroneous data
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    
    # delete points with erroneous gpstime, if most points have gpstime higher than seconds_per_week, points with lower gpstime can be considered wrong
    filter_erroneous_gpstime <- lasR::delete_points(filter = paste("gpstime <=", seconds_per_week))

    erroneous_gpstime <- summary_original$metrics$t_min <= seconds_per_week &&
      summary_original$metrics$t_median > seconds_per_week
    if (erroneous_gpstime) {
      pipeline <- pipeline + filter_erroneous_gpstime
    }

    # points with ReturnNumber or NumberOfReturns smaller 1 are erroneous
    filter_erroneous_returns <-
      lasR::delete_points(filter = "ReturnNumber < 1") +
      lasR::delete_points(filter = "NumberOfReturns < 1")

    pipeline <- pipeline + filter_erroneous_returns

    # pulses with high ScanAngles are sensitive to errors
    # filter_erroneous_scanangles <-
    #   lasR::delete_points(filter = "ScanAngle < -30") +
    #   lasR::delete_points(filter = "ScanAngle > 30")

    # pipeline <- pipeline + filter_erroneous_scanangles
  

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # select attributes (drop unnecessary)
    # keeping all point cloud attributes according to LAS 1.4 point data record format (PDRF) 6
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    select_attributes <- lasR::keep_attributes(c(
      "X", # | 4 bytes | X coordinate (scaled integer)
      "Y", # | 4 bytes | Y coordinate (scaled integer)
      "Z", # | 4 bytes | Z coordinate (scaled integer)
      "Intensity", # | 2 bytes | Return signal strength
      "ReturnNumber", # | 4 bits  | Which return this point represents (1–15)
      "NumberOfReturns", # | 4 bits  | Total returns for this pulse (1–15)
      "Synthetic", # | 1 bit   | Point created other than direct LiDAR acquisition
      "Keypoint", # | 1 bit   | Significant point, should not be withheld in thinning
      "Withheld", # | 1 bit   | Point should be excluded from processing
      "Overlap", # | 1 bit   | Point is in overlap region of two or more swaths
      "ScannerChannel", # | 2 bits  | Channel of the multi-channel system (0–3)
      "ScanDirectionFlag", # | 1 bit   | Direction of scanner mirror (0 = neg, 1 = pos, where positive scan direction is a scan moving from the left side of the in-track direction to the right side and negative the opposite)
      "EdgeOfFlightline", # | 1 bit   | 1 = last point on a scan line
      "Classification", # | 1 byte  | Full ASPRS class code (0–255)
      "UserData", # | 1 byte  | User-defined field
      "ScanAngle", # | 2 bytes | Scaled in 0.006° increments (±30,000 = ±180°)
      "PointSourceID", # | 2 bytes | File origin (e.g., flight line ID)
      "gpstime" # | 8 bytes | Standard GPS time
    ))

    pipeline <- pipeline + select_attributes

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify noise
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # cascading classification with ivf and multiple voxel sizes performed best in a small benchmark
    # https://gist.github.com/wiesehahn/59fd9c7037213cb058187b805912c5d5
    classify_noise <-
      lasR::classify_with_ivf(res = 2, n = 2, class = 7) + # catch individual outliers with small voxels
      lasR::classify_with_ivf(res = 5, n = 10, class = 7) + # catch small groups of outliers
      lasR::classify_with_ivf(res = 10, n = 40, class = 7) # catch larger groups of outliers

    # optional:
    # Calculate point density from summary
    # point_density <- summary_original$npoints /
    #   ((summary_original$metrics$x_max - summary_original$metrics$x_min) *
    #    (summary_original$metrics$y_max - summary_original$metrics$y_min))
    # filter_res <- 1
    # classify_noise <- lasR::classify_with_ivf(res = filter_res, n = filter_res * 3 * 3 * point_density * 0.2)

    # Adaptive parameters
    # if (point_density < 10) {
    #   classify_noise <- lasR::classify_with_sor(k = 10, m = 2.5)
    # } else if (point_density < 20) {
    #   classify_noise <- lasR::classify_with_sor(k = 15, m = 3.0)
    # } else {
    #   classify_noise <- lasR::classify_with_sor(k = 20, m = 3.5)
    # }
    # pipeline <- pipeline + classify_noise

    # option
    # # Stage 1: Remove extreme outliers (coarse filter)
    # classify_noise_coarse <- lasR::classify_with_sor(k = 50, m = 4)
    #
    # # Stage 2: Fine-tune (preserves valid low-density features)
    # classify_noise_fine <- lasR::classify_with_sor(k = 15, m = 3)
    #
    # pipeline <- pipeline + classify_noise_coarse + classify_noise_fine

    # option
    # # Stage 1: Remove extreme isolated points (fast)
    # classify_noise_ipf <- lasR::classify_with_ipf(r = 2, n = 0, class = 18)
    #
    # # Stage 2: Refine with SOR
    # classify_noise_sor <- lasR::classify_with_sor(k = 15, m = 3)
    #
    # pipeline <- pipeline + classify_noise_ipf + classify_noise_sor
    # classify_noise <- lasR::classify_with_sor(k = 15, m = 3)

    pipeline <- pipeline + classify_noise


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify ground
    # if point cloud does not contain any ground points (class 2)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    classify_ground <- lasR::classify_with_ptd()

    no_groundpoints <- !any(names(summary_original$npoints_per_class) == "2")
    if (no_groundpoints) {
      pipeline <- pipeline + classify_ground
    }


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # normalize Intensity range
    # intensities are clipped to 0.025-0.975 percentile range and stretched to values of 0-65535
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    normalize_intensity_range <- function(data) {
      lower_pct <- 0.025
      upper_pct <- 0.975
      min_val <- 0
      max_val <- 2^16 - 1

      i <- data$Intensity
      lower <- quantile(i, probs = lower_pct, na.rm = TRUE)
      upper <- quantile(i, probs = upper_pct, na.rm = TRUE)
      i <- (i - lower) / (upper - lower) * (max_val - min_val) + min_val
      i[i < min_val] <- min_val
      i[i > max_val] <- max_val
      data$Intensity <- as.integer(round(i))
      return(data)
    }

    intensity_range_normalization <- lasR::callback(normalize_intensity_range, expose = "i")
    pipeline <- pipeline + intensity_range_normalization


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # add Height Above Ground
    # this might drop points at the edges (https://github.com/r-lidar/lasR/issues/270)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # TODO
    # check whether we need HAG in the data. Advantage is we have min/max in summary, disadvantage is we delete edge points.
    # add_hag <- lasR::hag()
    # pipeline <- pipeline + add_hag


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # calculate summaries on processed data
    # summary and metrics per file
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    summarise_processed <- lasR::summarise(
      zwbin = 10, iwbin = 1000,
      metrics = c(
        "t_min", "t_median", "t_max",
        "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd",
        "z_min", "z_median", "z_max"
        # ,"HAG_min", "HAG_median", "HAG_max"
      )
    )

    pipeline <- pipeline + summarise_processed

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # sort points
    # (unnecessary if writing to COPC)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    sort_points <- lasR::sort_points()
    pipeline <- pipeline + sort_points

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # triangulate ground
    # mesh used for hulls
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    ground_triangulation <- lasR::triangulate(max_edge = 0, filter = lasR::keep_ground_and_water())
    pipeline <- pipeline + ground_triangulation

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get point cloud outlines (convex hulls)
    # (just necessary for data irregular tiles where not the entire tile contains data)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # outline_file <- fs::path(dir_outlines, fs::path_ext_set(generated_filename, "geojson"))
    # get_outlines <- lasR::hulls(ground_triangulation, ofile = outline_file)
    get_outlines <- lasR::hulls(ground_triangulation)
    pipeline <- pipeline + get_outlines

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create overview
    # more detailed overview primarily for human consumption, medium resolution, full spatial extent
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get CHM with 1 m resolution to use as overview images (1000x1000 px)
    overview_file <- fs::path(dir_overviews, fs::path_ext_set(generated_filename, ".tif"))
    get_overview <- lasR::rasterize(res = 1, operators = c("z_max"), filter = lasR::drop_noise(), ofile = overview_file)
    pipeline <- pipeline + get_overview

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # write point cloud to disk
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    write_pointcloud <- lasR::write_las(ofile = pointcloud_file, version = 4, pdrf = 6)
    pipeline <- pipeline + write_pointcloud

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # apply processing pipeline
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    ans <- lasR::exec(pipeline, on = las_in_memory, with = list(progress = FALSE, ncores = 1))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create spatial index
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    lasR::exec(lasR::write_lax(embedded = TRUE), on = ans$write_las, with = list(progress = FALSE, ncores = 1))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # save summaries to disk
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    save_summary <- function(summary_list, out_file) {
      summary <- lapply(summary_list, function(x) {
        if (is.data.frame(x)) {
          return(x)
        }
        if (is.atomic(x) && !is.null(names(x))) {
          return(as.list(lapply(x, as.integer)))
        }
        if (is.numeric(x)) {
          return(as.integer(x))
        }
        x
      })
      yyjsonr::write_json_file(summary, out_file, pretty = TRUE, auto_unbox = TRUE)
    }

    # Use ORIGINAL filename for original summary
    summary_original_json <- fs::path(dir_summary_original, fs::path_ext_set(original_filename, ".json"))
    summary_original |> save_summary(summary_original_json)

    # Use GENERATED filename for processed summary
    summary_processed <- ans$summary
    summary_processed_json <- fs::path(dir_summary_processed, fs::path_ext_set(generated_filename, ".json"))
    summary_processed |> save_summary(summary_processed_json)


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # save vpc to disk
    # add summary metadata and optionally update geometry
    #-------------------------------------------------------------------------------------------------------------------------------------------------#

    vpc <- resolve_vpc(pointcloud_file, epsg = epsg, out_file = NULL)

    # if point cloud covers less than 90% of tile extent
    # update geometry based on convex hull
    bbox_vals <- vpc$features$properties[[1]]$`proj:bbox`
    size_extent <- sf::st_area(
      sf::st_as_sfc(sf::st_bbox(
        c(
          xmin = bbox_vals[1], ymin = bbox_vals[2],
          xmax = bbox_vals[3], ymax = bbox_vals[4]
        ),
        crs = epsg
      ))
    )

    size_hull <- sf::st_area(ans$hulls)
    size_relative <- units::drop_units(size_hull / size_extent)

    if (size_relative < 0.9) {
      # Transform to WGS84 for geometry
      outline_wgs84 <- sf::st_transform(ans$hulls, 4326)
      geom_obj <- sf::st_geometry(outline_wgs84)[[1]]

      # Convert to GeoJSON coordinates
      if (inherits(geom_obj, "MULTIPOLYGON")) {
        coords <- lapply(geom_obj, function(poly) {
          lapply(poly, function(ring) {
            lapply(seq_len(nrow(ring)), function(j) round(ring[j, 1:2], 7))
          })
        })
        vpc$features$geometry[[1]] <- list(type = "MultiPolygon", coordinates = coords)
      } else {
        coords <- lapply(geom_obj, function(ring) {
          lapply(seq_len(nrow(ring)), function(j) round(ring[j, 1:2], 7))
        })
        vpc$features$geometry[[1]] <- list(type = "Polygon", coordinates = coords)
      }
    }

    metadata_content <- ans$summary
    # Add metadata if exists
    if (!is.null(metadata_content)) {
      new_props <- list()

      # Point density
      if (!is.null(size_hull)) {
        new_props$pointdensity <- round(metadata_content$npoints / size_hull, 2)
      }

      # Pulse density (first returns per square meter)
      if (!is.null(size_hull)) {
        first_returns <- metadata_content$npoints_per_return[["1"]]
        new_props$pulsedensity <- round(first_returns / size_hull, 2)
      }

      # Statistics array
      stats <- list()

      # Handle metrics as data.frame or list
      if (is.data.frame(metadata_content$metrics)) {
        metrics <- metadata_content$metrics[1, ]
      } else {
        metrics <- metadata_content$metrics[[1]]
      }

      # Z statistics
      stats[[length(stats) + 1]] <- list(
        name = "Z",
        minimum = round(metrics$z_min, 2),
        maximum = round(metrics$z_max, 2),
        mean = round(metrics$z_median, 2)
      )

      # Intensity statistics
      stats[[length(stats) + 1]] <- list(
        name = "Intensity",
        minimum = as.integer(metrics$i_min),
        maximum = as.integer(metrics$i_max),
        mean = round(metrics$i_mean, 2),
        median = as.integer(metrics$i_median),
        stddev = round(metrics$i_sd, 2)
      )

      # GpsTime statistics
      stats[[length(stats) + 1]] <- list(
        name = "GpsTime",
        minimum = as.integer(metrics$t_min),
        maximum = as.integer(metrics$t_max),
        median = as.integer(metrics$t_median)
      )

      # Classification statistics
      class_counts <- metadata_content$npoints_per_class
      class_list <- as.list(as.integer(class_counts))
      names(class_list) <- names(class_counts)

      stats[[length(stats) + 1]] <- list(
        name = "Classification",
        minimum = min(as.integer(names(class_counts))),
        maximum = max(as.integer(names(class_counts))),
        `class-count` = class_list
      )

      # ReturnNumber
      return_counts <- metadata_content$npoints_per_return
      return_list <- as.list(as.integer(return_counts))
      names(return_list) <- names(return_counts)

      stats[[length(stats) + 1]] <- list(
        name = "ReturnNumber",
        minimum = min(as.integer(names(return_counts))),
        maximum = max(as.integer(names(return_counts))),
        `class-count` = return_list
      )

      new_props$`pc:statistics` <- stats

      # Merge with existing properties
      current_props <- vpc$features$properties[[1]]
      vpc$features$properties[[1]] <- c(current_props, new_props)
    }

    # write VPC to disk
    vpc_file <- fs::path(dir_vpc, fs::path_ext_set(generated_filename, ".vpc"))
    yyjsonr::write_json_file(vpc, vpc_file, pretty = TRUE, auto_unbox = TRUE)


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # convert overview
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    ds <- new(gdalraster::GDALRaster, overview_file)
    ds$quiet <- TRUE
    mm <- ds$getStatistics(band = 1, approx_ok = FALSE, force = TRUE)
    ds$close()

    tmp_byte <- "/vsimem/tmp_byte.tif"
    gdalraster::translate(overview_file, tmp_byte, quiet = TRUE, cl_arg = c(
      "-ot", "Byte", "-scale", mm[1], mm[2], "0", "255", "-of", "GTiff"
    ))

    ds <- new(gdalraster::GDALRaster, tmp_byte, read_only = FALSE)
    cols <- viridis::viridis(256)
    rgb_mat <- col2rgb(cols)
    colortable <- cbind(0:255, t(rgb_mat), 255L)
    ds$setColorTable(band = 1, col_tbl = colortable, palette_interp = "RGB")
    ds$close()

    overview_img <- fs::path(dir_overviews, fs::path_ext_set(generated_filename, ".webp"))
    gdalraster::translate(tmp_byte, overview_img, cl_arg = c("-of", "WEBP", "-expand", "rgb"), quiet = TRUE)

    gdalraster::vsi_unlink(tmp_byte)
    fs::file_delete(overview_file)

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # cleanup memory
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    rm(las_in_memory)
    gc()

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # Create file log entry
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    status <- if (length(warnings) > 0) "success_with_warnings" else "success"
    file_log <- create_file_log(lasfile, pointcloud_file, status, file_start, warnings)

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # print information
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    n_points_in <- summary_original$npoints
    n_points_out <- summary_processed$npoints

    # Count noise points (class 7 and 18)
    count_noise <- function(npoints_per_class) {
      n <- 0
      if ("7" %in% names(npoints_per_class)) n <- n + npoints_per_class[["7"]]
      if ("18" %in% names(npoints_per_class)) n <- n + npoints_per_class[["18"]]
      n
    }

    n_noise_in <- count_noise(summary_original$npoints_per_class)
    n_noise_out <- count_noise(summary_processed$npoints_per_class)

    # Print information
    if (verbose) {
      message(sprintf("Process %s", basename(lasfile)))
      message(sprintf(
        "  \u25B6 %s (points/noise: %d/%d \u2192 %d/%d)",
        basename(pointcloud_file),
        n_points_in, n_noise_in, n_points_out, n_noise_out
      ))
    }

    # Return both output path and log entry
    return(list(output = pointcloud_file, log = file_log))
  }

  # ------------------------------------------------------------------
  # Setup and apply function
  # ------------------------------------------------------------------
  # use official EPSG definition
  gdalraster::set_config_option("GTIFF_SRS_SOURCE", "EPSG")

  # do not create .aux.xml files
  gdalraster::set_config_option("GDAL_PAM_ENABLED", "NO")

  # create directories if not existent
  dir_logfiles <- fs::dir_create(out_dir, "logfiles")
  dir_summary_original <- fs::dir_create(out_dir, "logfiles/summary_in")
  dir_summary_processed <- fs::dir_create(out_dir, "logfiles/summary_out")
  dir_pointcloud <- fs::dir_create(out_dir, "pointcloud")
  dir_overviews <- fs::dir_create(out_dir, "overviews")
  dir_vpc <- fs::dir_create(out_dir, "metadata")

  # Print header
  if (verbose) {
    message(sprintf("Process %d LASfiles", length(files)))
  }

  # apply function
  results <- map_las(files, raw_to_processed_per_file)

  output_paths <- lapply(results, function(x) if (is.null(x)) NULL else x$output)
  file_logs <- lapply(results, function(x) if (is.null(x)) NULL else x$log)


  # Finalize processing log
  processing_end <- Sys.time()
  processing_duration <- as.numeric(difftime(processing_end, processing_start, units = "secs"))

  log_data <- list(
    processing = list(
      function_call = deparse(match.call()),
      package_version = as.character(packageVersion("managelidar")),
      timestamp_start = format(processing_start, "%Y-%m-%dT%H:%M:%S"),
      timestamp_end = format(processing_end, "%Y-%m-%dT%H:%M:%S"),
      duration_seconds = round(processing_duration, 1)
    ),
    system = list(
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      platform = R.version$platform,
      os = Sys.info()["sysname"],
      user = Sys.info()["user"],
      hostname = Sys.info()["nodename"],
      dependencies = list(
        gdalraster = as.character(packageVersion("gdalraster")),
        fs = as.character(packageVersion("fs")),
        lasR = as.character(packageVersion("lasR")),
        mirai = as.character(packageVersion("mirai")),
        sf = as.character(packageVersion("sf"))
      )
    ),
    parameters = list(
      out_dir = normalizePath(out_dir, winslash = "/", mustWork = FALSE),
      epsg = epsg,
      region = region,
      from_csv = if (!is.null(from_csv)) normalizePath(from_csv, winslash = "/", mustWork = FALSE) else NULL
    ),
    files = file_logs
  )

  # Remove NULL values from parameters to avoid empty arrays in JSON
  log_data$parameters <- Filter(Negate(is.null), log_data$parameters)

  # Calculate summary statistics
  statuses <- sapply(file_logs, function(x) if (is.null(x)) "failed" else x$status)
  log_data$summary <- list(
    files_total = length(files),
    files_processed = sum(statuses %in% c("success", "success_with_warnings")),
    files_skipped_existing = sum(statuses == "skipped_existing"),
    files_failed = sum(statuses == "failed"),
    files_with_warnings = sum(statuses == "success_with_warnings")
  )

  # Write processing log
  log_filename <- sprintf("processing_log_%s.json", format(processing_start, "%Y-%m-%d_%H-%M-%S"))
  log_file <- fs::path(dir_logfiles, log_filename)
  yyjsonr::write_json_file(log_data, log_file, pretty = TRUE, auto_unbox = TRUE)

  if (verbose) {
    message(sprintf("\nProcessing log written to: %s", log_file))
  }

  # Return vector of output file paths (NULL for failed files)
  return(invisible(output_paths))
}
