sidebar <- dashboardSidebar(width = 200, hr(), {
  sidebarMenu(id = "tabs",
    menuItem("Phase 1", tabName = "tab_phase1", icon = icon("circle-o")),
    menuItem("Phase 2", tabName = "tab_phase2", icon = icon("circle-o")),
    menuItem("Phase 3", tabName = "tab_phase3", icon = icon("circle-o")),
    menuItem("Phase 4", tabName = "tab_phase4", icon = icon("circle-o")),
    tags$style(type = 'text/css',
      "footer{position: absolute; bottom:2%; left: 5%; padding:5px;}")
  )
})

#### Define body
body <- dashboardBody(
  useShinyjs(),
  tags$head(tags$link(rel="stylesheet", type="text/css", href="custom.css")),
  tabItems(

    tabItem(tabName = "tab_phase1",
      dtphase1::phase1UI("phase1")
    ),

    tabItem(tabName="tab_phase2", {
       shiny::includeMarkdown("phases/phase2/phase2.md")
     }),

    tabItem(tabName="tab_phase3", {
      phase3UI("phase3")
    })
    #
    # tabItem(tabName="tab_phase4", {
    #   phase4UI("phase4")
    # })
  ) #tabitems close
) #dashboard close

####  Define the dashboard
dashboardPage(
  skin    = "black",
  header  = dashboardHeader(titleWidth = 157, title = "Dashboard"),
  sidebar = sidebar,
  body    = body
)
