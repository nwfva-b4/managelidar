raw_to_processed <- function(path, out_dir = tempdir(), crs_epsg = 25832L, region = NULL, from_csv = NULL, verbose = TRUE) {

  # Initialize processing log
  processing_start <- Sys.time()

  # Constants
  seconds_per_week <- 604800L

  # ------------------------------------------------------------------
  # Early filename determination using check_names
  # Build VPC once for all files and determine expected filenames
  # ------------------------------------------------------------------
  files <- resolve_las_paths(path)

  if (length(files) == 0) {
    warning("No LAS/LAZ/COPC files found.")
    return(invisible(NULL))
  }

  # Build VPC once for efficiency
  vpc <- resolve_vpc(files, out_file = NULL)

  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  # Use check_names to get expected filenames (fast - uses VPC)
  name_check <- check_names(vpc, prefix = "3dm", region = NULL, from_csv = from_csv, full.names = TRUE)

  # Create lookup: original filename -> expected output filename
  filename_map <- setNames(
    basename(name_check$name_should),
    name_check$name_is
  )

  raw_to_processed_per_file <- function(lasfile){

    file_start <- Sys.time()
    file_log <- list()

    # Get original filename (for summary_original)
    original_filename <- fs::path_ext_remove(fs::path_file(lasfile))

    # Get expected filename from early check_names lookup
    expected_filename <- fs::path_ext_remove(filename_map[lasfile])

    # Define output file path
    pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(expected_filename, ".laz"))

    # Early existence check
    if (fs::file_exists(pointcloud_file)) {
      file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

      # Create file log entry
      file_log <- list(
        input = lasfile,
        output = pointcloud_file,
        status = "skipped_existing",
        duration_seconds = round(file_duration, 1)
      )

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

    # Try to get year from median GPS time
    if (!is.null(summary_original$metrics$t_median) &&
        summary_original$metrics$t_median > seconds_per_week) {
      # GPS time is seconds since 1980-01-06 00:00:00 UTC
      gps_epoch <- as.POSIXct("1980-01-06 00:00:00", tz = "UTC")
      date <- gps_epoch + summary_original$metrics$t_median + 1e9
      year_from_median <- format(date, "%Y")

      # Replace year in expected filename
      # Pattern: 3dm_32_547_5724_1_ni_YYYY.laz -> replace YYYY with year_from_median
      generated_filename <- sub("_([0-9]{4})$",
                                paste0("_", year_from_median),
                                expected_filename)
    }

    # Update output file path with final filename
    pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(generated_filename, ".laz"))

    # Check again if file exists with updated filename (edge case where year changed)
    if (generated_filename != expected_filename && fs::file_exists(pointcloud_file)) {
      file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

      # Cleanup memory
      rm(las_in_memory)
      gc()

      # Create file log entry
      file_log <- list(
        input = lasfile,
        output = pointcloud_file,
        status = "skipped_existing",
        duration_seconds = round(file_duration, 1)
      )

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Already processed (skipped)")
      }
      return(list(output = pointcloud_file, log = file_log))
    }

    # Check for ground points
    no_groundpoints <- !any(names(summary_original$npoints_per_class) == "2")
    if (no_groundpoints) {
      # Cleanup memory before early return
      rm(las_in_memory)
      gc()

      file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

      # Create file log entry
      file_log <- list(
        input = lasfile,
        output = NULL,
        status = "skipped_no_ground",
        duration_seconds = round(file_duration, 1)
      )

      if (verbose) {
        message(sprintf("Process %s", basename(lasfile)))
        message("  \u25B6 Skipped (no ground classification)")
      }
      return(list(output = NULL, log = file_log))
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
    set_crs <- lasR::set_crs(crs_epsg)

    # set CRS if missing valid EPSG
    missing_crs <- summary_original$epsg == 0L
    if (missing_crs) {
      pipeline <- pipeline + set_crs
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # filter erroneous data
    # delete points with erroneous gpstime, if most points have gpstime higher than seconds_per_week, points with lower gpstime can be considered wrong
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    filter_erroneous_gpstime <- lasR::delete_points(filter = paste("gpstime <=", seconds_per_week))

    erroneous_gpstime <- summary_original$metrics$t_min <= seconds_per_week &&
                        summary_original$metrics$t_median > seconds_per_week
    if (erroneous_gpstime) {
      pipeline <- pipeline + filter_erroneous_gpstime
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # filter erroneous data
    # points with ReturnNumber or NumberOfReturns smaller 1 are erroneous
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    filter_erroneous_returns <-
      lasR::delete_points(filter = "ReturnNumber < 1") +
      lasR::delete_points(filter = "NumberOfReturns < 1")

    pipeline <- pipeline + filter_erroneous_returns

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

    pipeline <- pipeline + select_attributes

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify noise
    #
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # TODO
    # check good parameter setting and ivf vs sor (ivf seems faster)
    # classify_noise <- lasR::classify_with_ivf()

    # option:
    # Calculate point density from summary
    # point_density <- summary_original$npoints /
    #            ((summary_original$metrics$x_max - summary_original$metrics$x_min) *
    #             (summary_original$metrics$y_max - summary_original$metrics$y_min))
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

    classify_noise <- lasR::classify_with_sor(k = 15, m = 3)
    pipeline <- pipeline + classify_noise


    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # classify ground
    # if point cloud does not contain any ground points (class 2)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # no_groundpoints <- !any(names(summary_original$npoints_per_class) == "2")
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
    # TODO
    # check whether we need HAG in the data. Advantage is we have min/max in summary, disadvantage is we delete edge points.
    # add_hag <- lasR::hag()
    # pipeline <- pipeline + add_hag

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
    # calculate summaries on processed data
    # summary and metrics per file
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    summarise_processed <- lasR::summarise(
      zwbin = 10, iwbin = 1000,
      metrics = c(
        "t_min", "t_median", "t_max",
        "i_min", "i_mean", "i_median", "i_max", "i_p5", "i_p95", "i_sd",
        "z_min", "z_median", "z_max",
        "HAG_min", "HAG_median", "HAG_max"
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
    ground_triangulation <- lasR::triangulate(max_edge = 25, filter = lasR::keep_ground_and_water())
    pipeline <- pipeline + ground_triangulation

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get point cloud outlines (convex hulls)
    # (just necessary for data irregular tiles where the entire tile is does not contain data)
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    outline_file <- fs::path(dir_outlines, fs::path_ext_set(generated_filename, ".gpkg"))
    get_outlines <- lasR::hulls(ground_triangulation, ofile = outline_file)
    pipeline <- pipeline + get_outlines

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # create overview
    # more detailed overview primarily for human consumption, medium resolution, full spatial extent
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # get CHM with 1 m resolution to use as overview images (1000x1000 px)
    overview_file <- fs::path(dir_overviews, fs::path_ext_set(generated_filename, ".tif"))
    get_overview <- lasR::rasterize(res = 1, operators = c("z_max"), ofile = overview_file)
    pipeline <- pipeline + get_overview

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # write point cloud to disk
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    write_pointcloud <- lasR::write_las(ofile = pointcloud_file)
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
    # create virtual point cloud
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # TODO
    # this will create a VPC per file, do we need this?
    # a VPC per collection will be created later
    # should we enrich the VPC with further metadata (summary, outline, ...)?
    # we will create VPC later anyway, and summary here anyway, is there a benefit of creating it here per file?#
    # we can easily append summary later, but what about refs to overviews, raw data, ...
    # should we just create summary and append those things there? then later when creating vpc per collection we can append summary
    # in step below (save summaries) we can add path to processed las, path to original las, path to overview, path to logfile, ...
    vpc_file <- fs::path(dir_vpc, fs::path_ext_set(generated_filename, ".vpc"))
    lasR::exec(lasR::write_vpc(ofile = vpc_file, use_gpstime = TRUE), on = ans$write_las, with = list(progress = FALSE, ncores = 1))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # save summaries to disk
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    save_summary <- function(summary_list, out_file) {
      summary <- lapply(summary_list, function(x) {
        if (is.data.frame(x)) return(x)
        if (is.atomic(x) && !is.null(names(x))) return(as.list(lapply(x, as.integer)))
        if (is.numeric(x)) return(as.integer(x))
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

    file_duration <- as.numeric(difftime(Sys.time(), file_start, units = "secs"))

    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    # Create file log entry
    #-------------------------------------------------------------------------------------------------------------------------------------------------#
    status <- if (length(warnings) > 0) "success_with_warnings" else "success"

    file_log <- list(
      input = lasfile,
      output = pointcloud_file,
      status = status,
      duration_seconds = round(file_duration, 1)
    )

    if (length(warnings) > 0) {
      file_log$warnings <- warnings
    }

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
      message(sprintf("  \u25B6 %s (points/noise: %d/%d \u2192 %d/%d)",
                      basename(pointcloud_file),
                      n_points_in, n_noise_in, n_points_out, n_noise_out))
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
  dir_summary_original <- fs::dir_create(out_dir, "summary_original")
  dir_summary_processed <- fs::dir_create(out_dir, "metadata")
  dir_pointcloud <- fs::dir_create(out_dir, "pointcloud")
  dir_outlines <- fs::dir_create(out_dir, "outlines")
  dir_overviews <- fs::dir_create(out_dir, "overviews")
  dir_vpc <- fs::dir_create(out_dir, "vpcs")
  dir_logfiles <- fs::dir_create(out_dir, "logfiles")

  # Print header
  if (verbose) {
    message(sprintf("Process %d LASfiles", length(files)))
  }

  # apply function
  results <- map_las(files, raw_to_processed_per_file)

  # Extract output paths and log entries
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
      duration_seconds = round(processing_duration)
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
      crs_epsg = crs_epsg,
      region = region,
      from_csv = from_csv
    ),
    files = file_logs
  )

  # Calculate summary statistics
  statuses <- sapply(file_logs, function(x) if (is.null(x)) "failed" else x$status)
  log_data$summary <- list(
    files_total = length(files),
    files_processed = sum(statuses %in% c("success", "success_with_warnings")),
    files_skipped_existing = sum(statuses == "skipped_existing"),
    files_skipped_no_ground = sum(statuses == "skipped_no_ground"),
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
