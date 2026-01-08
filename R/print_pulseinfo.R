#' Print summary information about pulse density and penetration ratio
#'
#' `print_pulseinfo()` computes and prints summary statistics of
#' LiDAR pulse density, point density, and penetration rates
#' (single vs. multiple returns).
#'
#' @param path The path to a LAS file (.las/.laz/.copc), to a directory which contains LAS files, or to a Virtual Point Cloud (.vpc) referencing LAS files.
#'
#' @details
#' The function uses [get_density()] to calculate average
#' pulse and point densities, and [get_penetration()] to
#' compute average penetration rates for single and multiple
#' returns.
#'
#' This function is intended for exploratory reporting and prints
#' aggregated statistics to the console. It does not return values.
#'
#' @return
#' Invisibly returns `NULL`. The function is called for its
#' side effect of printing to the console.
#'
#' @export
#'
#' @examples
#' f <- system.file("extdata", package = "managelidar")
#' print_pulseinfo(f)
#'
print_pulseinfo <- function(path) {

  # ------------------------------------------------------------------
  # Density statistics
  # ------------------------------------------------------------------
  density <- get_density(path)

  avg_pulse <- round(mean(density$pulsedensity, na.rm = TRUE), 1)
  avg_point <- round(mean(density$pointdensity, na.rm = TRUE), 1)

  # ------------------------------------------------------------------
  # Penetration statistics
  # ------------------------------------------------------------------
  penetration <- get_penetration(path)

  to_pct <- function(x) {
    round(mean(x, na.rm = TRUE) * 100, 1)
  }

  avg_single   <- to_pct(penetration$single)
  avg_multiple <- to_pct(penetration$multiple)
  avg_two      <- to_pct(penetration$two)
  avg_three    <- to_pct(penetration$three)
  avg_four     <- to_pct(penetration$four)
  avg_five     <- to_pct(penetration$five)
  avg_six      <- to_pct(penetration$six)

  # ------------------------------------------------------------------
  # Print
  # ------------------------------------------------------------------
  cat(glue::glue("
Density (⌀):
----------------
Pulse Density : {avg_pulse} pulses/m²
Point Density : {avg_point} points/m²

Pulse Penetration Rate (⌀):
----------------
Single Returns   : {avg_single} %
Multiple Returns : {avg_multiple} %
  Two Returns    : {avg_two} %
  Three Returns  : {avg_three} %
  Four Returns   : {avg_four} %
  Five Returns   : {avg_five} %
  Six Returns    : {avg_six} %
"))

  invisible(NULL)
}

