
# inspiration: https://github.com/georgewoolsey/cloud2trees/blob/main/R/lasr_pipeline.R

# TODO: update pipeline

# add verbosity

# optimize for parallel processing?

# get list of processed files, unprocessed, reasons

# optimize noise classification
# which algorithm?
# Which settings?
# density based?

# outline as geojson (requires reprojection)?


# reclassify data prior to 2021 to new AdV schema
#   Klasse_bis_2020 = c(2, 7, 8, 11, 12, 13, 15, 20, 22, 23, 25, 26, 27)
#   Klasse_ab_2021 = c(2, 7, 9, 8, 24, 20, 1, 12, 12, 12, 12, 12, 12)

# rename tiles

# integrate summaries and outline in vpc?
# add raw_source, script(version), density to vpc.

raw_to_processed <- function(path, out_dir = tempdir()) {

  raw_to_processed_per_file <- function(lasfile){

  # get filename (to store related data under same name)
  filename <- fs::path_ext_remove(fs::path_file(lasfile))

  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # read pointcloud in memory
  # used instead of reader() to only read data once for first summarising and following main processing pipeline
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  las_in_memory <- lasR::read_cloud(lasfile)

  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # calculate summaries on unprocessed data
  # metrics are used in main processing pipeline
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


  # TODO
  # currently processing stops early if pointcloud does not have ground points
  # once classify_with_ptd() is implemented in lasR, remove this part and modify pipeline below
  no_groundpoints <- !any(names(summary_unprocessed$npoints_per_class) == "2")
  if (no_groundpoints) {return("data without ground classification")}



  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # initialze pipeline with reading stage
  # this does nothing here as data is already read in memoryits only purpose is to initialize a pipeline we can add other stages to
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  pipeline <-
    lasR::reader()


  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # set CRS
  # explicitly set the CRS if it is is not set or cannot properly be read (https://github.com/r-lidar/lasR/issues/265)
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # EGSP 25832 is default for all cadastral data in western federal states of Germany
  set_crs <- lasR::set_crs(25832)

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
  # check good paraemter setting and ivf vs sor (ivf seems faster)
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
  pointcloud_file <- fs::path(dir_pointcloud, fs::path_ext_set(filename, ".laz"))
  write_pointcloud <- lasR::write_las(ofile = pointcloud_file)

  pipeline <- pipeline +
    write_pointcloud


  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # apply processing pipeline
  #
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  ans <- lasR::exec(pipeline, on = las_in_memory, with = list(progress = TRUE, ncores = 1))


  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # create spatial index
  #
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  lasR::exec(lasR::write_lax(embedded = TRUE), on = ans$write_las, with = list(progress = TRUE, ncores = 1))


  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # create virtual point cloud
  #
  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  vpc_file <- fs::path(dir_vpc, fs::path_ext_set(filename, ".vpc"))
  lasR::exec(lasR::write_vpc(ofile = vpc_file, use_gpstime = TRUE), on = ans$write_las, with = list(progress = TRUE, ncores = 1))


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
  mm <- ds$getStatistics(band = 1, approx_ok = FALSE, force = TRUE)
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
  gdalraster::translate(tmp_byte, overview_img, cl_arg = c("-of", "WEBP", "-expand", "rgb"))

  # cleanup
  gdalraster::vsi_unlink(tmp_byte)
  fs::file_delete(overview_file)


  #-------------------------------------------------------------------------------------------------------------------------------------------------#
  # print information
  #
  #-------------------------------------------------------------------------------------------------------------------------------------------------#

  n_points_unprocessed <- summary_unprocessed$npoints
  n_points_processed <- summary_processed$npoints


  # print information
  cat("LASin contained", n_points_unprocessed, "points;",
      "LASout contains", n_points_processed, "points",
      "(", n_points_unprocessed - n_points_processed, " filtered)")

  # TODO
  # get detailed density information?
  # sf::st_area(ans$hulls)
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

  # apply function
  map_las(files, raw_to_processed_per_file)
}


