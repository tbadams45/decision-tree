server <- function(input, output, session) {
  callModule(dtphase1::phase1, "phase1")

  # no call is necessary for phase 2, as everything is included in the html file
  # compiled from phase2.Rmd

  callModule(phase3,
             "phase3",
             surface_data = surface_data,
             parc_data    = parcoords_data)

  callModule(phase4,
             "phase4",
             adap_results = adap_results,
             base_clim    = base_clim,
             CMIP5        = CMIP5)
}
