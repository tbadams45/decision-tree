# install and load packages.
if (!require("pacman")) install.packages("pacman") # package managment tool
pacman::p_load(stats, plyr, magrittr, truncnorm, RColorBrewer, sirad, tidyr, readr, lubridate, ggplot2, LaplacesDemon, mvtnorm, shiny, shinyjs, shinyBS, htmlwidgets, shinythemes, shinydashboard, plotly, dplyr, wrviz, devtools, ggthemes, rmarkdown)
pacman::p_load_gh(c("timelyportfolio/parcoords", "tbadams45/wrviz", "tbadams45/dtphase1", "rstudio/DT"))
if(packageVersion("DT") < "0.1.57") {
  pacman::p_install_gh(c("rstudio/DT"))
  pacman::p_load_gh(c("rstudio/DT"))
}

# generate markdown file for phase 2
rmarkdown::render('phases/phase2/phase2.Rmd')

source("phases/phase3/phase3.R")

# generate synthetic data for phase 3 -----------------------------------------

## create data for climate heatmap/surface plot ###############################

ch_dataset <- c("Princeton", "GPCC", "CRU")
ch_size    <- seq(50, 110, by = 10) # size of dam we're simulating
ch_temp    <- 0:5 # temperature increase from historical baseline, in celsius.
ch_prec    <- seq(0.7, 1.4, by = 0.1) # precipitation change from historical: 1.0 = no change
ch_nvar    <- 1:10 # realization number for particular precip/temperature combo
ch_demand  <- seq(30, 105, by = 15)

surface_data <- expand.grid(dataset = ch_dataset,
                            size = ch_size,
                            temp = ch_temp,
                            prec = ch_prec,
                            nvar = ch_nvar,
                            demand = ch_demand,
                            stringsAsFactors = FALSE)

# dummy equations, designed to give a rough sense of what a climate heatmap
# would look like. Very loosely based off of multiple regression analysis of
# real data.
reliability_princeton <- function(demand, size, temp, prec, nvar){
  77 + 0.045 * size - 0.3 * demand - 0.025 * nvar - 0.15 * temp + 18.5 * prec
}

crit_reliability_princeton <- function(demand, size, temp, prec, nvar){
  val <- 80 + 0.15 * size - 0.2 * demand - 0.2 * nvar - 1 * temp + 11 * prec
  ifelse(val > 100, 100, val)
  val
}

safeyield_princeton <- function(demand, size, temp, prec, nvar) {
  20.5 + 0.16 * size - 0.45 * temp + 55 * prec
}

surface_data <- as.tbl(mutate(surface_data,
  reliability = reliability_princeton(demand, size, temp, prec, nvar),
  creliability = crit_reliability_princeton(demand, size, temp, prec, nvar),
  safeyield = safeyield_princeton(demand, size, temp, prec, nvar)))

surface_data_mean <- surface_data %>%
  group_by(dataset, size, demand, temp, prec) %>%
  summarize(reliability = mean(reliability), creliability = mean(creliability),
    safeyield = mean(safeyield)) %>% mutate(nvar = 0)

surface_data %<>% bind_rows(surface_data_mean)

# surface_data <- read_csv("./data/stresstest_ffd.csv", progress = FALSE) %>%
#   mutate(reliability = rel, creliability = crel) %>%
#   mutate(demand = multipleReplace(demand, what=c(57, 68, 80, 91, 103, 114),
#     by=c(50, 80, 110, 140, 170, 200)))



## create data for parallel coordinates plot ###################################

# sample output from from a Latin Hypercube Sampling simulation run of a systems
# model, which accounts for both climatic and non-climatic factors.
parcoords_data <- data.frame(
  size = rep(seq(80, 160, by = 20), 1000),
  n    = sort(rep(1:1000, 5)),
  Q    = rnorm(5000, mean = 9, sd = 2.3),
  NPV  = rnorm(5000, mean = 900, sd = 360),
  var  = rep(4, 5000),
  dem  = rep(102, 5000),
  sed  = rep(0.56, 5000),
  prc  = rep(1.24, 5000),
  dsc  = rep(0.066, 5000),
  dtemp = rep(0.30, 5000)
)


# parc_data <- read_csv("./data/LHS_output.csv", progress = FALSE)
