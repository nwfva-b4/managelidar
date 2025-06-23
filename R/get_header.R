
#' Get the Fileheader (Metadata) from LAS files
#'
#' Provides a simple wrapper to read the metadata included in the fileheader from LAS files.
#'
#' @param path The path to a file (.las/.laz/.copc), to a directory which contains these files, or to a virtual point cloud (.vpc) referencing these files.
#' @param full.names Whether to return the full file path or just the file name (default)
#'
#' @return A named list of LASheaders
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' get_header(f)

get_header <- function(path, full.names = FALSE, verbose = FALSE){

  get_header_file <- function(file){

if (endsWith(file, ".las") | endsWith(file, ".laz")) {

  fileheader <- lidR::readLASheader(file)

    }

    if (full.names == FALSE){
      file <- basename(file)
    }

    return(list(filename = file, header = fileheader))

  }

  if (file.exists(path) && !dir.exists(path)) {

    # Virtual Point Cloud
    if (tools::file_ext(path) == "vpc") {
      vpc <- yyjsonr::read_json_file(path)
      f <- sapply(vpc$features$assets, function(x) x$data$href)
      result <- lapply(f, get_header_file)
      names(result) <- sapply(result, function(x) basename(x$file))
      return(result)
    }
    # LAZ file
    else if (tools::file_ext(path) %in% c("las", "laz")) {
      result <- list(get_header_file(path))
      names(result) <- basename(result[[1]]$file)
      return(result)
    } else {
      stop("Unsupported file format. Supported formats: .las, .laz, .vpc")
    }
  }

  # Folder Path
  else if (dir.exists(path)) {

    f <- list.files(path, pattern = "\\.(las|laz)$", full.names = TRUE)
    result <- lapply(f, get_header_file)
    names(result) <- sapply(result, function(x) basename(x$file))
    return(result)
  } else {
    stop("Path does not exist: ", path)
  }

}
