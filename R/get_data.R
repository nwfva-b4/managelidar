
#' Get data in a standardized format
#'
#' This function copies data from one folder to another folder, while ensuring certain data formatting and folder structure. CRS is set, points are sorted, files are compressed, files are renamed according to [ADV standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111), files are ordered in folders by acquisition date and campaign, a VPC is created and files are spatially indexed.
#'
#' @param origin The path to a directory which contains (unprocessed) las/laz files
#' @param destination The directory under which the processed files are copied and subfolders (year/campaign) are created
#' @param campaign (character) Name of the project or campaign of data acquisition.
#' @param origin_recurse boolean. Should files in subfolder be included?
#'
#' @return A structured copy of input lidar data
#' @export
#'
#' @examples
#' \dontrun{
#' f <- system.file("extdata", package = "managelidar")
#' get_data(f, tempdir(), "landesbefliegung")
#' }
get_data <- function(origin, destination, campaign, origin_recurse = FALSE) {

  # create temporary folder
  tmpfolder <- fs::dir_create(fs::path(destination, "in_process"), recurse = TRUE)
  # create documentary folder
  docufolder <- fs::dir_create(fs::path(destination, "doku"), recurse = TRUE)


  # just in case process stopped
  processed_files <- list.files(tmpfolder, pattern = "/*.laz$")
  all_files <- list.files(origin, pattern = "/*.las|z$", full.names = TRUE, recursive = origin_recurse)
  unprocessed_files <- setdiff(tools::file_path_sans_ext(basename(all_files)), tools::file_path_sans_ext(basename(processed_files)))
  unprocessed_files <- all_files[tools::file_path_sans_ext(basename(all_files)) %in% unprocessed_files]

  lasR::exec(
    # set CRS (for the case it is not correctly set)
    lasR::set_crs(25832) +
      # sort points for better compression and efficient reading
      lasR::sort_points(spatial = TRUE) +
      # write compressed
      lasR::write_las(ofile = paste0(tmpfolder, "/*.laz")),
    with = list(ncores = lasR::concurrent_files(lasR::half_cores()), progress = TRUE),
    on = unprocessed_files
  )

  # rename files according to ADV standard
  managelidar::set_names(path = tmpfolder)


  now <- as.integer(format(Sys.time(), "%Y"))
  for (year in c(2000:now)) {
    files_to_move <- list.files(path = tmpfolder, pattern = paste0("*", year, ".laz$"), full.names = TRUE)

    if (length(files_to_move) > 0) {
  # sort files in folders by year
      destination_dir <- fs::path(destination, year, campaign)
      fs::dir_create(destination_dir, recurse = TRUE)
      destination_files <- file.path(destination_dir, basename(files_to_move))
      file.rename(files_to_move, destination_files)

      vpc <- file.path(docufolder, paste0(campaign, "_", year, ".vpc"))
      lasR::exec(
        # create spatial index for faster processing
        lasR::write_lax(embedded = TRUE) +
      # create virtual point cloud
        lasR::write_vpc(ofile = vpc, use_gpstime = TRUE, absolute_path = TRUE),
        with = list(ncores = lasR::concurrent_files(lasR::half_cores()), progress = TRUE),
        on = destination_files
      )
    }
  }

  unlink(tmpfolder, recursive = TRUE)


}





