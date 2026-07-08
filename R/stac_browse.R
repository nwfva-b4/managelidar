#' Browse a STAC catalog
#'
#' Opens a STAC catalog (created with [stac_create_catalog()]) in your
#' browser so you can explore its collections and items visually.
#'
#' @param catalog Path to `catalog.json` (the root of the STAC tree).
#'
#' @return Nothing (called for its side effect of opening a browser).
#'
#' @examples
#' cat <- tempfile("stac-managelidar-") |>
#'   stac_create_catalog(id = "lidar_ni") 
#' col <- cat |>
#'   stac_add_collection(id = "lidar_ni", title = "Lidar Solling")
#' cat |> stac_browse()
#'
#' @export
stac_browse <- function(catalog) {
  if (!fs::file_exists(catalog)) {
    cli::cli_abort("Catalog file does not exist: {.path {catalog}}")
  }

  root_dir <- fs::path_dir(fs::path_abs(catalog))
  port <- httpuv::randomPort()

  app <- list(call = function(req) stac_browse_handle_request(req, root_dir))
  httpuv::startServer("127.0.0.1", port, app)

  browser_url <- sprintf(
    "https://radiantearth.github.io/stac-browser/#/external/http://localhost:%d/catalog.json",
    port
  )

  cli::cli_alert_success("Opening catalog in your browser...")
  utils::browseURL(browser_url)

  invisible()
}

#' Handle a single HTTP request for stac_browse()
#' @param req httpuv request object
#' @param root_dir Root directory to serve files from
#' @return httpuv response list
#' @keywords internal
stac_browse_handle_request <- function(req, root_dir) {
  if (req$REQUEST_METHOD == "OPTIONS") {
    return(list(status = 204L, headers = stac_browse_cors_headers(), body = ""))
  }

  rel_path <- utils::URLdecode(sub("^/", "", req$PATH_INFO))
  if (rel_path == "") rel_path <- "catalog.json"

  file_path <- fs::path(root_dir, rel_path)

  # Guard against escaping root_dir via ../
  if (!startsWith(fs::path_real(file_path), fs::path_real(root_dir))) {
    return(list(status = 403L, headers = stac_browse_cors_headers(), body = "Forbidden"))
  }

  if (!fs::file_exists(file_path) || fs::is_dir(file_path)) {
    return(list(status = 404L, headers = stac_browse_cors_headers(), body = "Not found"))
  }

  list(
    status = 200L,
    headers = c(
      stac_browse_cors_headers(),
      list("Content-Type" = stac_browse_mime_type(file_path))
    ),
    body = readBin(file_path, "raw", fs::file_info(file_path)$size)
  )
}

#' @keywords internal
stac_browse_cors_headers <- function() {
  list(
    "Access-Control-Allow-Origin" = "*",
    "Access-Control-Allow-Methods" = "GET, OPTIONS",
    "Access-Control-Allow-Headers" = "*"
  )
}

#' @keywords internal
stac_browse_mime_type <- function(path) {
  ext <- tolower(fs::path_ext(path))
  switch(
    ext,
    json = "application/json",
    geojson = "application/geo+json",
    html = "text/html",
    "application/octet-stream"
  )
}