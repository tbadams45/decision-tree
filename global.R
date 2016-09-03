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
source("phases/phase4/phase4.R")
source("phases/phase4/climate_robustness.R")

# GENERATE SYNTHETIC DATA FOR PHASE 3 ------------------------------------------

# equations designed to give a rough sense of what a climate heatmap
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


## create data for climate heatmap/surface plot

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

surface_data <- as.tbl(mutate(surface_data,
  reliability = reliability_princeton(demand, size, temp, prec, nvar),
  creliability = crit_reliability_princeton(demand, size, temp, prec, nvar),
  safeyield = safeyield_princeton(demand, size, temp, prec, nvar)))

surface_data_mean <- surface_data %>%
  group_by(dataset, size, demand, temp, prec) %>%
  summarize(reliability = mean(reliability), creliability = mean(creliability),
    safeyield = mean(safeyield)) %>% mutate(nvar = 0)

surface_data %<>% bind_rows(surface_data_mean)

## create data for parallel coordinates plot

# sample output from from a Latin Hypercube Sampling simulation run of a systems
# model, which accounts for both climatic and non-climatic factors.
parcoords_data <- data.frame(
  size = rep(seq(50, 110, by = 10), 1000),
  NPV  = rnorm(7000, mean = 900, sd = 360),
  dem  = rnorm(7000, mean = 82, sd = 16),
  sed  = rnorm(7000, mean = 0.75, sd = 0.15),
  prc  = rnorm(7000, mean = 1, sd = 0.17),
  dsc  = rnorm(7000, mean = 0.05, sd = 0.018),
  dtemp = rnorm(7000, mean = 2, sd = 1.20),
  dprec = rnorm(7000, mean = 1.1, sd = 0.412)
)



# GENERATE SYNTHETIC DATA FOR PHASE 4 ------------------------------------------

# CMIP5 projections for temperature and precipitation change
CMIP5 <- read_csv("phases/phase4/CMIP5_deltaclim.csv") %>%
  mutate(del_prec = del_prec/100 + 1) %>%
  rename(Scenario = scenario)

# calculate cost in millions of USD
cost <- function(size) {
  size * 4
}

# calculate domestic reliability of dam with given design/operating decisions
reliability_domestic <- function(temp, precip, size, prio, alpha, beta) {
  temp*20 + precip*20 + size*0.8 + prio*20 + alpha*20 + beta*20
}

# calculate irrigation reliability of dam with given design/operating decisions
reliability_irrigation <- function(temp, precip, size, prio, alpha, beta) {
  temp*25 + precip*15 + size*0.4 + prio*25 + alpha*18 + beta*15
}

# calculate environmental reliability of dam with given design/operating decisions
reliability_environmental <- function(temp, precip, size, prio, alpha, beta) {
  temp*15 + precip*25 + size*0.6 + prio*10 + alpha*30 + beta*10
}

# calculate domestic critical reliability of dam with given design/operating decisions
creliability_domestic <- function(temp, precip, size, prio, alpha, beta) {
  temp*10 + precip*40 + size*0.5 + prio*40 + alpha*10 + beta*30
}

# sample output of simulation exploring different decision and operating
# decisions
adap_results <- expand.grid(
  temp     = ch_temp,
  precip   = ch_prec,
  K        = ch_size,
  prio     = 1:3,
  alpha    = seq(0.5, 0.9, by = 0.2),
  beta     = seq(0.4, 1, by = 0.3),
  stringsAsFactors = FALSE
)

adap_results <- as.tbl(mutate(adap_results,
  dom_rel = reliability_domestic(temp, precip, K, prio, alpha, beta),
  irr_rel = reliability_irrigation(temp, precip, K, prio, alpha, beta),
  eco_rel = reliability_environmental(temp, precip, K, prio, alpha, beta),
  dom_crel = creliability_domestic(temp, precip, K, prio, alpha, beta),
  cost = cost(K)
))

# normalize performance metrics to [0, 100] range
min_dr  <- min(adap_results$dom_rel)
max_dr  <- max(adap_results$dom_rel)
min_ir  <- min(adap_results$irr_rel)
max_ir  <- max(adap_results$irr_rel)
min_er  <- min(adap_results$eco_rel)
max_er  <- max(adap_results$eco_rel)
min_dcr <- min(adap_results$dom_crel)
max_dcr <- max(adap_results$dom_crel)

adap_results <- as.tbl(mutate(adap_results,
  dom_rel  = 80 + ((dom_rel - min_dr) * (100 - 80) / (max_dr - min_dr)),
  irr_rel  = 80 + ((irr_rel - min_ir) * (100 - 80) / (max_ir - min_ir)),
  eco_rel  = 80 + ((eco_rel - min_er) * (100 - 80) / (max_er - min_er)),
  dom_crel = 80 + ((dom_crel - min_dcr) * (100 - 80) / (max_dcr - min_dcr))
))

# output of simulation with historical climate
base_clim <- filter(adap_results, temp == 0 & precip == 1)
base_clim <- mutate(base_clim,
  ID = as.numeric(rownames(base_clim)),
  dom_rel = round(dom_rel, 2),
  irr_rel = round(irr_rel, 2),
  eco_rel = round(eco_rel, 2),
  dom_crel = round(dom_crel, 2))
