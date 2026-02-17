# data-raw/solling_sample.R

# Note: This script requires access to the original data source
# It documents how the sample data was created

# get sample data from ALS campaign "Solling 2023", "Solling 2024" and downsample to 10m to reduce file size


# 4 tiles for 2024
path2024 <- "L:/luftbilder/ni/digitalbefliegungen/befliegungen_2024/solling_sgb4/daten/laserscan/klassifizierte_Laserdaten/"
f2024 <- c(
  paste0(path2024, "3dm_32_547_5724_1_ni_20240327.laz"),
  paste0(path2024, "3dm_32_548_5724_1_ni_20240327.laz"),
  paste0(path2024, "3dm_32_547_5725_1_ni_20240327.laz"),
  paste0(path2024, "3dm_32_548_5725_1_ni_20240327.laz")
)

# one tile for 2023
f2023 <- "L:/luftbilder/ni/digitalbefliegungen/befliegungen_2023/solling_nlf/01_to_laz/3dm_32_548_5725_1_ni_20230904.laz"


# Downsample to 10m and save (+ explicitly set CRS)
pipeline <- lasR::reader(filter = "-thin_with_grid 10.0") + lasR::set_crs(25832) + lasR::write_las(file.path("inst/extdata", "*.laz"))

lasR::exec(pipeline, on = f2024)
lasR::exec(pipeline, on = f2023)


# create sample vpc
vpc_path <- file.path("inst/extdata", "sample.vpc")
las_files <- list.files("inst/extdata", full.names = T, pattern = "*20240327.laz")
lasR::exec(lasR::write_vpc(vpc_path, use_gpstime = TRUE), on = las_files)
