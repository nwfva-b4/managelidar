#' Filter VPC features by attribute values
#'
#' Filters VPC features based on property values using dplyr-style expressions.
#'
#' @param path Character vector of input paths, a VPC file path, or a VPC object
#'   already loaded in R. Can be a mix of LAS/LAZ/COPC files and `.vpc` files.
#' @param ... Logical expressions using property names. Multiple conditions are
#'   combined with AND. Use backticks for properties with special characters
#'   (e.g., `` `pc:count` > 10000 ``).
#' @param verbose Logical. If TRUE (default), prints information about filtering results.
#'
#' @return A VPC object (list) containing only features matching the criteria.
#'   Returns NULL invisibly if no features match the filter.
#'
#' @details
#' This function filters VPC features based on their properties using familiar
#' dplyr-style syntax. You can use standard comparison operators and combine
#' multiple conditions.
#'
#' **Available properties in standard VPCs:**
#'
#' Standard VPC files (as created by lasR) contain these properties:
#' \itemize{
#'   \item `id` - Feature identifier (exposed for convenience, not in properties)
#'   \item `datetime` - Acquisition date/time (ISO 8601 format)
#'   \item `` `pc:count` `` - Total point count
#'   \item `` `pc:type` `` - Point cloud type (typically "lidar")
#'   \item `` `proj:bbox` `` - Projected bounding box (xmin, ymin, xmax, ymax)
#'   \item `` `proj:epsg` `` - EPSG code of the CRS
#'   \item `` `proj:wkt2` `` - WKT2 CRS definition
#' }
#'
#' Enriched VPCs (created with \code{\link{create_vpc_enriched}}) also contain:
#' \itemize{
#'   \item `pointdensity` - Points per square meter
#'   \item `pulsedensity` - Pulses per square meter
#'   \item `` `pc:statistics` `` - Statistical summaries (nested structure)
#' }
#'
#' **Note:** For spatial and temporal filtering, use the dedicated functions
#' \code{\link{filter_spatial}} and \code{\link{filter_temporal}} which handle
#' coordinate transformations and date parsing automatically.
#'
#' **Supported operators:**
#' \itemize{
#'   \item Comparison: `>`, `>=`, `<`, `<=`, `==`, `!=`
#'   \item Set membership: `%in%`
#'   \item Logical: `&` (and), `|` (or), `!` (not)
#' }
#'
#' **Using property names:**
#' \itemize{
#'   \item Properties without special characters can be used directly: `datetime`, `id`
#'   \item Properties with `:` or `-` require backticks: `` `pc:count` ``, `` `proj:epsg` ``
#'   \item String values need quotes: `` `pc:type` == "lidar" ``
#' }
#'
#' Features missing the specified properties are excluded from results.
#'
#' @export
#'
#' @seealso \code{\link{filter_temporal}}, \code{\link{filter_spatial}},
#'   \code{\link{filter_multitemporal}}
#'
#' @examples
#' folder <- system.file("extdata", package = "managelidar")
#'
#' # Filter by point count (use backticks for properties with special chars)
#' folder |>
#'   filter_attribute(`pc:count` > 5000)
#'
#' # Filter by type
#' folder |>
#'   filter_attribute(`pc:type` == "lidar")
#'
#' # Multiple conditions (AND)
#' folder |>
#'   filter_attribute(`pc:count` > 5000, `pc:type` == "lidar")
#'
#' # Using OR
#' folder |>
#'   filter_attribute(`pc:count` > 10000 | `pc:type` == "lidar")
#'
#' # Filter by feature ID (exposed for convenience)
#' folder |>
#'   filter_attribute(id == "3dm_32_547_5724_1_ni_20240327")
#'
#' # Filter by multiple IDs
#' folder |>
#'   filter_attribute(id %in% c(
#'     "3dm_32_547_5724_1_ni_20240327",
#'     "3dm_32_548_5724_1_ni_20240327"
#'   ))
#'
#' # Filter enriched VPC by density
#' folder |>
#'   create_vpc_enriched() |>
#'   filter_attribute(pointdensity >= 10)
#'
#' # Chain with dedicated filter functions
#' folder |>
#'   filter_temporal("2024-03") |>
#'   filter_attribute(`pc:count` > 5000) |>
#'   filter_spatial(c(547900, 5724900, 548100, 5725100))
#'
#' # Note: For spatial/temporal filtering, prefer dedicated functions:
#' folder |>
#'   filter_temporal("2024-03-27") # Better than filter_attribute(datetime == ...)
#'
#' folder |>
#'   filter_spatial(bbox) # Better than filter_attribute with proj:bbox
filter_attribute <- function(path, ..., verbose = TRUE) {
  # Resolve to VPC (always as object, never write to file)
  vpc <- resolve_vpc(path, out_file = NULL)

  # Check if resolve_vpc returned NULL
  if (is.null(vpc)) {
    return(invisible(NULL))
  }

  n_input <- nrow(vpc$features)

  if (n_input == 0) {
    warning("No features in VPC to filter")
    return(invisible(NULL))
  }

  # Capture expressions
  dots <- rlang::enquos(...)

  if (length(dots) == 0) {
    warning("No filter conditions provided")
    return(vpc)
  }

  # Create a data frame-like environment for each feature to evaluate expressions
  keep <- rep(TRUE, n_input)

  for (expr in dots) {
    # Evaluate expression for each feature
    results <- vapply(seq_len(n_input), function(i) {
      # Create environment with feature properties
      props <- vpc$features$properties[[i]]

      # Also add id for convenience (not technically in properties)
      if (!is.null(vpc$features$id[i])) {
        props$id <- vpc$features$id[i]
      }

      # Evaluate expression in this environment
      tryCatch(
        {
          result <- rlang::eval_tidy(expr, data = props)
          if (is.na(result) || is.null(result)) {
            return(FALSE)
          }
          return(as.logical(result))
        },
        error = function(e) {
          # Property doesn't exist or other error
          return(FALSE)
        }
      )
    }, FUN.VALUE = logical(1))

    # Combine with AND logic
    keep <- keep & results
  }

  # No matches found
  if (sum(keep) == 0) {
    warning("No features match filter criteria")
    return(invisible(NULL))
  }

  vpc$features <- vpc$features[keep, , drop = FALSE]

  n_output <- nrow(vpc$features)

  # Print information
  if (verbose) {
    # Format the filter description
    expr_text <- vapply(dots, function(e) rlang::as_label(e), character(1))
    filter_desc <- paste(expr_text, collapse = " & ")

    message("Filter by attribute")
    message(sprintf("  \u25BC %d LASfiles (%s)", n_input, filter_desc))
    message(sprintf("  \u25BC %d LASfiles retained", n_output))
  }

  return(vpc)
}
