rnd_down <- function(x, nearest) {
  floor(x/nearest)*nearest
}

rnd_up <- function(x, nearest) {
  ceiling(x/nearest)*nearest
}

rnd <- function(x, nearest) {
  round(x/nearest)*nearest
}

# capatalize the first letter in a string.
cap_first <- function(x) {
  paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
}