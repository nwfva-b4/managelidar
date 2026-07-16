# create example STAC catalog

load_all()

folder <- fs::path_package("extdata", package = "managelidar")

las_files_2024 <- fs::dir_ls(folder, glob = "*20240327.laz")
las_files_2023 <- fs::dir_ls(folder, glob = "*20230904.laz")

# create STAC catalog
cat <- fs::path(folder, "stac") |>
  stac_create_catalog(id = "example_catalog",
                      title = "Example Catalog",
                      description = "This is an example for a Spatio Temporal Asset Catalog (STAC) created via {[managelidar](https://github.com/nwfva-b4/managelidar)} R-package.",
                      icon = "https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png")

providers <- list(
  list(
    name = "Example Providername",
    roles = c("host", "producer", "processor", "licensor"),
    url = "https://github.com/nwfva-b4/managelidar"
  ),
  list(
    name = "Another provider",
    roles = c("host", "processor"),
    url = "https://github.com/nwfva-b4/managelidar"
  )
)

# add STAC collection1
col1 <- cat |>
  stac_add_collection(id = "example_collection1",
                      title = "Example Collection #1",
                      license = " 	CC-BY-4.0",
                      description = "This is an example for a STAC-collection, there can be multiple collections per catalog and also collections within collections.",
                      keywords = c("example", "test", "collection"),
                      thumbnail = "https://ps.w.org/kama-thumbnail/assets/icon-256x256.png?rev=2836004",
                      providers = providers)

# add STAC collection2
col2 <- cat |>
  stac_add_collection(id = "example_collection2",
                      title = "Example Collection #2",
                      description = "This is another collection at the same hierach level than `Example collection #1`",
                      keywords = c("example"),
                      icon = "https://cdn-icons-png.flaticon.com/256/628/628647.png")

# add STAC collection as subcollection1
subcol1 <- col1 |>
  stac_add_collection(id = "example_subcollection1",
                      title = "Example subcollection #1",
                      keywords = c("subcollection", "test"),
                      providers = list("name" = "Examplename", "roles" = "host"),
                      overview = "https://raw.githubusercontent.com/nwfva-b4/managelidar/refs/heads/main/man/figures/logo.png")

# add STAC collection as subcollection2
subcol2 <- col1 |>
  stac_add_collection(id = "example_subcollection2",
                      title = "Example subcollection #2")


# add LASfiles from 2023 as items
items1 <- subcol1 |>
  stac_add_items(path = las_files_2023)

# add LASfiles from 2024 as items
items2 <- subcol2 |>
  stac_add_items(path = las_files_2024)
