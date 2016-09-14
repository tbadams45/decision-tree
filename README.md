# decision-tree

This [shiny app](https://tbadams.shinyapps.io/decision-tree/) serves as an introduction to the [Decision Tree Framework](https://openknowledge.worldbank.org/handle/10986/22544) used for climate change risk management for water resources projects. Its focus is to familiarize the user with the types of questions that are asked in each phase, and with the visualizations and graphics that are frequently used to answer these questions. 

This app was primarily built by Tim Adams while serving as a Research Assistant at the University of Massachusetts Amherst. [Umit Taner](https://www.researchgate.net/profile/Mehmet_Taner3) developed most of the initial code for Phase 3, which served as the starting point for the rest of the app. Direction, insight, and valuable feedback were provided by [Patrick Ray](https://www.researchgate.net/profile/Patrick_Ray3).

You can [view the app online](https://tbadams.shinyapps.io/decision-tree/) or download it to run it locally. If local, run the code below first to install the necessary packages.

```r 
if(!require("devtools")) {
  install.packages("devtools")
}
install.packages("stats")
install.packages("plyr")
install.packages("magrittr")
install.packages("truncnorm")
install.packages("RColorBrewer")
install.packages("sirad")
install.packages("tidyr")
install.packages("readr")
install.packages("lubridate")
install.packages("ggplot2")
install.packages("LaplacesDemon")
install.packages("mvtnorm")
install.packages("shiny")
install.packages("shinyjs")
install.packages("shinyBS")
install.packages("htmlwidgets")
install.packages("shinythemes")
install.packages("shinydashboard")
install.packages("plotly")
install.packages("dplyr")
install.packages("ggthemes")
install.packages("rmarkdown")
devtools::install_github("tbadams45/wrviz")
devtools::install_github("tbadams45/dtphase1")
devtools::install_github("timelyportfolio/parcoords")
devtools::install_github("rstudio/DT")

```
