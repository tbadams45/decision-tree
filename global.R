# install and load packages.
if (!require("pacman")) install.packages("pacman") # package managment tool
if(!require("dtphase1")) pacman::p_install_gh("tbadams45/dtphase1")
pacman::p_load(shiny, dtphase1, shinydashboard, shinyjs)
