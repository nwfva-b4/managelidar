#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# Column/variable names referenced via non-standard evaluation (dplyr verbs,
# data.frame column access) that R CMD check cannot otherwise resolve as
# defined - see https://r-pkgs.org/data.html#sec-data-tidyverse
utils::globalVariables(c(
  "assets", "correct", "date_from_file", "date_source", "filename", "from",
  "gpstime", "href", "lan_name", "minx", "miny", "multitemporal",
  "name_is", "name_should", "observations", "proj:bbox", "tile", "to",
  "xmin", "ymin"
))
