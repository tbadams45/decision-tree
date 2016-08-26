server <- function(input, output, session) {
  callModule(dtphase1::phase1, "phase1")
  # callModule(phase2, "phase2")
  # callModule(phase3, "phase3")
  # callModule(phase4, "phase4")
}
