
# get sample data from ALS campaign "Solling 2024" and downsample to 10m to reduce file size

path <- "L:/luftbilder/aktuell/2024/Solling_20240327/Laserscan/klassifizierte_Laserdaten/"
f <- c(paste0(path, "3dm_32_547_5724_1_ni_20240327.laz"),
       paste0(path, "3dm_32_548_5724_1_ni_20240327.laz"),
       paste0(path, "3dm_32_547_5725_1_ni_20240327.laz"),
       paste0(path, "3dm_32_548_5725_1_ni_20240327.laz")
       )

laz_files <- lasR::exec(lasR::reader(filter = "-thin_with_grid 10.0") + lasR::write_las(here::here("inst/extdata", "*.laz")), on = f)

