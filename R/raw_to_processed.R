
raw_to_processed <- function(path, out_dir = tempdir(), crs_epsg = 25832L, verbose = TRUE) {

  # Initialize processing log
  processing_start <- Sys.time()
  log_data <- list(
    processing = list(
      function_call = deparse(match.call()),
      package_version = as.character(packageVersion("managelidar")),
      timestamp_start = format(processing_start, "%Y-%m-%dT%H:%M:%S%z")
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
      out_dir = out_dir,
      crs_epsg = crs_epsg
    ),
    files = list()
  )

  raw_to_processed_per_file <- function(lasfile){

    file_start <- Sys.time()

    # get filename (to store related data under same name)
    filename <- fs::path_ext_remove(fs::path_file(lasfile))

    # Define output file path
    pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(filename, ".laz"))

    # Check if file already processed
    if (fs::file_exists(pointcloud_file)) {
      file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

      # Log file info
      log_data$files <<- c(log_data$files, list(list(
        input = lasfile,
        output = pointcloud_file,
        status = "skipped_existing",
        duration_seconds = round(file_duration, 2)
      )))

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Already processed (skipped)")
      }
      return(pointcloud_file)
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # read pointcloud in memory
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    las_in_memory <- lasR::read_cloud(lasfile, progress = FALSE)

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # calculate summaries on unprocessed data
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    summarise_unprocessed <- lasR::summarise(
      zwbin = 50, iwbin = 100,
      metrics = c(
        "x_min", "x_max", "y_min", "y_max",
        "t_min", "t_median", "t_max",
        "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd",
        "z_min", "z_median", "z_max"
      )
    )
    summary_unprocessed <- lasR::exec(summarise_unprocessed, on = las_in_memory, with = list(progress = FALSE, ncores = 1))

    # Check for ground points
    no_groundpoints <- !any(names(summary_unprocessed$npoints_per_class) == "2")
    if (no_groundpoints) {
      # Cleanup memory before early return
      rm(las_in_memory)
      gc()

      file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

      # Log file info
      log_data$files <<- c(log_data$files, list(list(
        input = lasfile,
        output = NULL,
        status = "skipped_no_ground",
        duration_seconds = round(file_duration, 2)
      )))

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Skipped (no ground classification)")
      }
      return(invisible(NULL))
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # initialize pipeline with reading stage
    # this does nothing here as data is already read in memory, its only purpose is to initialize a pipeline we can add other stages to
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    pipeline <-
      lasR::reader()


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # set CRS
    # explicitly set the CRS if it is is not set or cannot properly be read (https://github.com/r-lidar/lasR/issues/265)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # EGSP 25832 is default for all cadastral data in western federal states of Germany
    set_crs <- lasR::set_crs(crs_epsg)

    # set CRS if missing valid EPSG
    missing_crs <- summary_unprocessed$epsg == 0L
    if (missing_crs) {pipeline <- pipeline +
      set_crs}


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # filter erroneous data
    # delete points with erroneous gpstime, if most points have gpstime higher than seconds_per_week, points with lower gpstime can be considered wrong
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    seconds_per_week <- 604800L
    filter_erroneous_gpstime <- lasR::delete_points(filter = paste("gpstime <=", seconds_per_week))

    erroneous_gpstime <- summary_unprocessed$metrics$t_min <= seconds_per_week && summary_unprocessed$metrics$z_median > seconds_per_week
    if (erroneous_gpstime) {pipeline <- pipeline +
      filter_erroneous_gpstime}


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # filter erroneous data
    # points with ReturnNumber or NumberOfReturns smaller 1 are erroneous
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    filter_erroneous_returns <-
      lasR::delete_points(filter = "ReturnNumber < 1") +
      lasR::delete_points(filter = "NumberOfReturns < 1")

    pipeline <- pipeline +
      filter_erroneous_returns


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # select attributes (drop unnecessary)
    # keeping all point cloud attributes according to LAS 1.4 point data record format (PDRF) 6
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    select_attributes <- lasR::keep_attributes(c(
      "X",                  # | 4 bytes | X coordinate (scaled integer)
      "Y",                  # | 4 bytes | Y coordinate (scaled integer)
      "Z",                  # | 4 bytes | Z coordinate (scaled integer)
      "Intensity",          # | 2 bytes | Return signal strength
      "ReturnNumber",       # | 4 bits  | Which return this point represents (1–15)
      "NumberOfReturns",    # | 4 bits  | Total returns for this pulse (1–15)
      "Synthetic",          # | 1 bit   | Point created other than direct LiDAR acquisition
      "Keypoint",           # | 1 bit   | Significant point, should not be withheld in thinning
      "Withheld",           # | 1 bit   | Point should be excluded from processing
      "Overlap",            # | 1 bit   | Point is in overlap region of two or more swaths
      "ScannerChannel",     # | 2 bits  | Channel of the multi-channel system (0–3)
      "ScanDirectionFlag",  # | 1 bit   | Direction of scanner mirror (0 = neg, 1 = pos, where positive scan direction is a scan moving from the left side of the in-track direction to the right side and negative the opposite)
      "EdgeOfFlightline",   # | 1 bit   | 1 = last point on a scan line
      "Classification",     # | 1 byte  | Full ASPRS class code (0–255)
      "UserData",           # | 1 byte  | User-defined field
      "ScanAngle",          # | 2 bytes | Scaled in 0.006° increments (±30,000 = ±180°)
      "PointSourceID",      # | 2 bytes | File origin (e.g., flight line ID)
      "gpstime"             # | 8 bytes | Standard GPS time
    ))

    pipeline <- pipeline +
      select_attributes


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify noise
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # TODO
    # check good parameter setting and ivf vs sor (ivf seems faster)
    # classify_noise <- lasR::classify_with_ivf()

    # # coarse-scale filter with 50 neighbors to find points/clusters
    # # statistically far from the main cloud mass
    # lasR::classify_with_sor(k =  50, m = 4) +
    # # fine-scale filter with 15 neighbors and a tighter threshold of 3 sd's
    # # (3-sigma rule) to find outlier points based on local neighborhood
    classify_noise <- lasR::classify_with_sor(k =  15, m = 3)

    pipeline <- pipeline +
      classify_noise


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify ground
    # if point cloud does not contain any ground points (class 2)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # no_groundpoints <- !any(names(summary_unprocessed$npoints_per_class) == "2")
    #
    # if (no_groundpoints) {
    #   classify_ground <- lasR::classify_with_ptd()
    #
    #   pipeline <- pipeline +
    #     classify_ground
    #   }


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # add Height Above Ground
    # this might drop points at the edges (https://github.com/r-lidar/lasR/issues/270)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    add_hag <- lasR::hag()

    pipeline <- pipeline +
      add_hag


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # normalize Intensity range
    # intensities are clipped to 0.025-0.975 percentile range and stretched to values of 0-65535
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    normalize_intensity_range <- function(data) {

      lower_pct = 0.025
      upper_pct = 0.975

      min_val <- 0
      max_val <- 2^16 - 1

      i <- data$Intensity

      # Compute percentiles
      lower <- quantile(i, probs = lower_pct, na.rm = TRUE)
      upper <- quantile(i, probs = upper_pct, na.rm = TRUE)

      # Scale intensities based on percentiles
      i <- (i - lower) / (upper - lower) * (max_val - min_val) + min_val

      # Clip values to min/max
      i[i < min_val] <- min_val
      i[i > max_val] <- max_val

      # Convert to integer
      data$Intensity <- as.integer(round(i))

      return(data)
    }

    intensity_range_normalization <- lasR::callback(normalize_intensity_range, expose = "i")

    pipeline <- pipeline +
      intensity_range_normalization


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # calculate summaries on processed data
    # summary and metrics per file
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    summarise_processed <- lasR::summarise(
      zwbin = 10, iwbin = 1000,
      metrics = c(
        "t_min", "t_median", "t_max",
        "i_min", "i_mean", "i_median", "i_max",
        "i_p5", "i_p95", "i_sd",
        "z_min", "z_median", "z_max",
        "HAG_min", "HAG_median", "HAG_max"
      )
    )

    pipeline <- pipeline +
      summarise_processed


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # sort points
    # (unnecessary if writing to COPC)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    sort_points <- lasR::sort_points()

    pipeline <- pipeline +
      sort_points


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # triangulate ground
    # mesh used for hulls
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    ground_triangulation  <- lasR::triangulate(max_edge = 25, filter = lasR::keep_ground_and_water())

    pipeline <- pipeline +
      ground_triangulation


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get point cloud outlines (convex hulls)
    # (just necessary for data irregular tiles where the entire tile is does not contain data)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    outline_file <- fs::path(dir_outlines, fs::path_ext_set(filename, ".gpkg"))
    get_outlines <- lasR::hulls(ground_triangulation, ofile = outline_file)

    pipeline <- pipeline +
      get_outlines


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create overview
    # more detailed overview primarily for human consumption, medium resolution, full spatial extent
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get CHM with 1 m resolution to use as overview images (1000x1000 px)
    overview_file <- fs::path(dir_overviews, fs::path_ext_set(filename, ".tif"))
    get_overview <- lasR::rasterize(res = 1, operators = c("z_max"), ofile = overview_file)

    pipeline <- pipeline +
      get_overview


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # write point cloud to disk
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # pointcloud_file already defined at top of function
    write_pointcloud <- lasR::write_las(ofile = pointcloud_file)

    pipeline <- pipeline +
      write_pointcloud


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # apply processing pipeline
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    ans <- lasR::exec(pipeline, on = las_in_memory, with = list(progress = FALSE, ncores = 1))


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create spatial index
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    lasR::exec(lasR::write_lax(embedded = TRUE), on = ans$write_las, with = list(progress = FALSE, ncores = 1))


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create virtual point cloud
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    vpc_file <- fs::path(dir_vpc, fs::path_ext_set(filename, ".vpc"))
    lasR::exec(lasR::write_vpc(ofile = vpc_file, use_gpstime = TRUE), on = ans$write_las, with = list(progress = FALSE, ncores = 1))


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # save summaries to disk
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    save_summary <- function(summary_list, out_file) {
      summary <- lapply(summary_list, function(x) {
        if (is.data.frame(x)) return(x)
        # named vectors (e.g. histograms) become lists to preserve names as JSON keys
        # whole numbers stored as double → integer (its all number of points)
        if (is.atomic(x) && !is.null(names(x))) return(as.list(lapply(x, as.integer)))
        if (is.numeric(x)) return(as.integer(x))
        x
      })

      yyjsonr::write_json_file(summary, out_file, pretty = TRUE, auto_unbox = TRUE)
    }

    summary_unprocessed_json <- fs::path(dir_summary_unprocessed, fs::path_ext_set(filename, ".json"))
    summary_unprocessed |> save_summary(summary_unprocessed_json)

    summary_processed <- ans$summary
    summary_processed_json <- fs::path(dir_summary_processed, fs::path_ext_set(filename, ".json"))
    summary_processed |> save_summary(summary_processed_json)


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # convert overview
    # 1-band Geotiff to 3-band pseudocolor WEBP
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get actual min/max first
    ds <- new(gdalraster::GDALRaster, overview_file)
    invisible(capture.output(
      mm <- ds$getStatistics(band = 1, approx_ok = FALSE, force = TRUE)
    ))
    ds$close()

    # scale Float32 to Byte (0-255) into GDAL virtual memory
    tmp_byte <- "/vsimem/tmp_byte.tif"
    gdalraster::translate(overview_file, tmp_byte, quiet = TRUE, cl_arg = c(
      "-ot", "Byte", "-scale", mm[1], mm[2], "0", "255", "-of", "GTiff"
    ))

    # attach viridis color table
    ds <- new(gdalraster::GDALRaster, tmp_byte, read_only = FALSE)
    cols <- viridis::viridis(256)
    rgb_mat <- col2rgb(cols)
    colortable <- cbind(0:255, t(rgb_mat), 255L)
    ds$setColorTable(band = 1, col_tbl = colortable, palette_interp = "RGB")
    ds$close()

    # expand pseudocolor to RGB and save as WEBP
    overview_img <- fs::path(dir_overviews, fs::path_ext_set(filename, ".webp"))
    gdalraster::translate(tmp_byte, overview_img, cl_arg = c("-of", "WEBP", "-expand", "rgb"), quiet = TRUE)

    # cleanup
    gdalraster::vsi_unlink(tmp_byte)
    fs::file_delete(overview_file)


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # cleanup memory
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    rm(las_in_memory)
    gc()

    file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # Log file info
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    log_data$files <<- c(log_data$files, list(list(
      input = lasfile,
      output = pointcloud_file,
      status = "success",
      duration_seconds = round(file_duration, 2)
    )))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # print information
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    n_points_in <- summary_unprocessed$npoints
    n_points_out <- summary_processed$npoints

    # Count noise points (class 7 and 18) for input - safely handle missing classes
    n_noise_in <- 0
    class_names_in <- names(summary_unprocessed$npoints_per_class)
    if ("7" %in% class_names_in) {
      n_noise_in <- n_noise_in + summary_unprocessed$npoints_per_class[["7"]]
    }
    if ("18" %in% class_names_in) {
      n_noise_in <- n_noise_in + summary_unprocessed$npoints_per_class[["18"]]
    }

    # Count noise points (class 7 and 18) for output - safely handle missing classes
    n_noise_out <- 0
    class_names_out <- names(summary_processed$npoints_per_class)
    if ("7" %in% class_names_out) {
      n_noise_out <- n_noise_out + summary_processed$npoints_per_class[["7"]]
    }
    if ("18" %in% class_names_out) {
      n_noise_out <- n_noise_out + summary_processed$npoints_per_class[["18"]]
    }

    # Print information
    if (verbose) {
      message(sprintf("Process %s", basename(lasfile)))
      message(sprintf("  \u25B6 %s (points/noise: %d/%d \u2192 %d/%d)",
                      basename(pointcloud_file),
                      n_points_in, n_noise_in, n_points_out, n_noise_out))
    }

    # Return file path
    return(pointcloud_file)
  }

  # ------------------------------------------------------------------
  # apply function
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # use official EPSG definition instead of potentially tweaked GeoTIFF-embedded CRS params
  gdalraster::set_config_option("GTIFF_SRS_SOURCE", "EPSG")

  # do not create .aux.xml files (Persistent Auxiliary Metadata) for rasters
  gdalraster::set_config_option("GDAL_PAM_ENABLED", "NO")

  # create directories if not existent
  dir_summary_unprocessed <- fs::dir_create(out_dir, "summary_unprocessed")
  dir_summary_processed <- fs::dir_create(out_dir, "summary_processed")
  dir_pointcloud <- fs::dir_create(out_dir, "pointcloud")
  dir_outlines <- fs::dir_create(out_dir, "outlines")
  dir_overviews <- fs::dir_create(out_dir, "overviews")
  dir_vpc <- fs::dir_create(out_dir, "vpcs")

  # Print header
  if (verbose) {
    message(sprintf("Process %d LASfiles", length(files)))
  }

  # apply function
  results <- map_las(files, raw_to_processed_per_file)

  # Finalize processing log
  processing_end <- Sys.time()
  processing_duration <- as.numeric(difftime(processing_end, processing_start, units = "secs"))

  log_data$processing$timestamp_end <- format(processing_end, "%Y-%m-%dT%H:%M:%S%z")
  log_data$processing$duration_seconds <- round(processing_duration, 2)

  # Calculate summary statistics
  statuses <- sapply(log_data$files, function(x) x$status)
  log_data$summary <- list(
    files_total = length(files),
    files_processed = sum(statuses == "success"),
    files_skipped_existing = sum(statuses == "skipped_existing"),
    files_skipped_no_ground = sum(statuses == "skipped_no_ground"),
    files_failed = sum(statuses == "failed")
  )

  # Write processing log
  log_filename <- sprintf("processing_log_%s.json", format(processing_start, "%Y-%m-%d_%H-%M-%S"))
  log_file <- fs::path(out_dir, log_filename)
  yyjsonr::write_json_file(log_data, log_file, pretty = TRUE, auto_unbox = TRUE)

  if (verbose) {
    message(sprintf("\nProcessing log written to: %s", log_file))
  }

  # Return vector of output file paths (NULL for failed files)
  return(invisible(results))
}
