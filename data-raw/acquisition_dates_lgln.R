# get file with acquition dates for lower saxony (by LGLN)
library(dplyr)


# List all files recursively
all_files <- fs::dir_ls("L:/lidar/aktuell/ALS_Flugdatum_Punktdichte_LGLN/v2", type = "file", recurse = TRUE)
# Filter to files where the name starts with L and ends with .gpkg
files <- all_files[grepl("^L.*\\.gpkg$", fs::path_file(all_files))]

merged_data <- files |>
  purrr::map(sf::st_read, quiet = TRUE) |>
  bind_rows() |>
  rename(date = Flugdatum) |>
  mutate(
    zone = as.numeric(paste0(3, substr(be1, 1, 1))),
    minx = as.numeric(substr(be1, 2, 4)),
    miny = as.numeric(substr(be1, 5, 8)),
    date = as.Date(date, format = "%Y-%m-%d")
  ) |>
  select(zone, minx, miny, date) |>
  sf::st_drop_geometry()

write.csv(merged_data, "inst/extdata/acquisition_dates_lgln.csv", row.names = FALSE)
