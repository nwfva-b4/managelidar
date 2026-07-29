sample_data_dir <- function() {
  system.file("extdata", package = "managelidar")
}

sample_las_files <- function() {
  list.files(sample_data_dir(), pattern = "[.]laz$", full.names = TRUE)
}
