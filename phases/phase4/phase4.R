
source("phases/utils.R", local = TRUE)

################################################################################
################################  UI  ##########################################
################################################################################

# Main UI function. base_clim is the results of our simulation with historical
# temperature and precipitation.
phase4UI <- function(id, base_clim){
  ns <- NS(id)

  tabsetPanel(
    tabPanel("Objective and Decision Spaces", value = ns("obj_dec_spaces"),
      fluidPage(
        fluidRow(
          box(width = 12, title = "Using this tool", status = "primary",
            collapsible = TRUE,
            includeMarkdown("www/phase4_help1.md")
          ) #close box
        ), #close fluidRow
        fluidRow(
          box(width = 12, title = "Objective Space",
            status = "primary", align = "left",
            fluidRow(
              column(width = 3,
                sliderInput(ns("dom_rel_filter"),
                  "Domestic Reliability Range",
                  min = floor(min(base_clim$dom_rel)),
                  max = ceiling(max(base_clim$dom_rel)),
                  value = c(floor(min(base_clim$dom_rel)),
                    ceiling(max(base_clim$dom_rel))),
                  step = 0.2,
                  round = -1
                )), #close sliderINput and column
              column(width = 3,
                sliderInput(ns("irr_rel_filter"),
                  "Irrigation Reliability Range",
                  min = floor(min(base_clim$irr_rel)),
                  max = ceiling(max(base_clim$irr_rel)),
                  value = c(floor(min(base_clim$irr_rel)),
                    ceiling(max(base_clim$irr_rel))),
                  step = 0.2,
                  round = -1
                )), #close sliderInput and column
              column(width = 3,
                sliderInput(ns("dom_crel_filter"),
                  "Domestic Crit. Reliability Range",
                  min = floor(min(base_clim$dom_crel)),
                  max = ceiling(max(base_clim$dom_crel)),
                  value = c(floor(min(base_clim$dom_crel)),
                    ceiling(max(base_clim$dom_crel))),
                  step = 0.2,
                  round = -1
                )), #close sliderInput and column
              column(width = 3,
                actionButton(ns("filterDataButton"),
                  "Filter"),
                actionButton(ns("resetDataButton"),
                  "Reset"))
            ), #close inputs fluidRow
            fluidRow(parcoordsOutput(ns("obj_space")))
          )), #close objective space box and fluidRow
        fluidRow(
          box(width = 12, title = "Decision Space", status="primary",
            height = 400, dataTableOutput(ns("dec_space_dt"))
          ) #close box
        ) # close fluidRow
      )), # close fluidPage and tabPanel
    tabPanel("Climate Robustness Analysis", value = ns("clim_space"),
      fluidPage(
        fluidRow(
          box(width = 12, title = "Using this tool", status = "primary",
            collapsible = TRUE,
            includeMarkdown("www/phase4_help2.md")
          ),

          fluidRow(
            box(width = 3, title = "Selected Metric to Examine:",
              selectInput(
                ns("metric_select"),
                label = "Select metric to plot on the heatmaps below:",
                choices = list(
                  "Domestic Reliability" = "dom_rel",
                  "Irrigiation Reliability" = "irr_rel",
                  "Environmental Reliability" = "eco_rel",
                  "Domestic Critical Reliability" = "dom_crel"
                )
              )
            ),
            box(width = 9, title = "Potential Designs",
              dataTableOutput(ns("design_select_dt")))
          ),

          box(width=6, title="Climate Robustness Results",
            climate_robustnessUI(ns("climate1"))
          ), # close box

          box(width=6, title="Climate Robustness Results",
            climate_robustnessUI(ns("climate2"))
          ) # close box
        ))) # close fluidRow, fluidPage, and tabPanel
  ) # close tabset panel
} # close ui function


################################################################################
############################## SERVER ##########################################
################################################################################


# Main server function.
phase4 <- function(input, output, session, base_clim, adap_results, CMIP5){

  # used for resetting of our parcoords.
  tags$script(
    "
function reset_brush(id){
  HTMLWidgets.find('#' + id).parcoords.brushReset();
}
"
  )

  # generate axes to use for parallel coordinates plot. You'll need to choose
  # the "dimensions" argument in the parcoords() function too...
  pc_axes_adap <- c("ID", "cost","dom_rel","irr_rel","eco_rel", "dom_crel")

  obj_space_default_data <- select(base_clim, one_of(pc_axes_adap))
  obj_space_disp_data <- reactiveValues(d = obj_space_default_data)
  v <- reactiveValues(reset = 0)

  filter_obj <- observeEvent(input$filterDataButton, {
    # filter based on sliders
    data  <- obj_space_default_data %>%
      filter(between(dom_rel, input$dom_rel_filter[1], input$dom_rel_filter[2])) %>%
      filter(between(irr_rel, input$irr_rel_filter[1], input$irr_rel_filter[2])) %>%
      filter(between(dom_crel, input$dom_crel_filter[1], input$dom_crel_filter[2]))

    # or filter based on highlighted data
    #data <- select(obj_space_selected(), one_of(pc_axes_adap))

    # update sliders so that their min and max values match with what's shown
    updateSliderInput(session, "dom_rel_filter",
      min = floor(min(data$dom_rel)),
      max = ceiling(max(data$dom_rel)))
    updateSliderInput(session, "irr_rel_filter",
      min = floor(min(data$irr_rel)),
      max = ceiling(max(data$irr_rel)))
    updateSliderInput(session, "dom_crel_filter",
      min = floor(min(data$dom_crel)),
      max = ceiling(max(data$dom_crel)))



    # assign to reactiveValue
    obj_space_disp_data$d <- data

  })

  reset_obj <- observeEvent(input$resetDataButton, {
    obj_space_disp_data$d <- obj_space_default_data
    tags$script(HTML(paste0("reset_brush(", session$ns("obj_space"), ")")))
    updateSliderInput(session, "dom_rel_filter",
      min = floor(min(obj_space_default_data$dom_rel)),
      max = ceiling(max(obj_space_default_data$dom_rel)),
      value = c(floor(min(obj_space_default_data$dom_rel)),
                ceiling(max(obj_space_default_data$dom_rel))))
    updateSliderInput(session, "irr_rel_filter",
      min = floor(min(obj_space_default_data$irr_rel)),
      max = ceiling(max(obj_space_default_data$irr_rel)),
      value = c(floor(min(obj_space_default_data$irr_rel)),
                ceiling(max(obj_space_default_data$irr_rel))))
    updateSliderInput(session, "dom_crel_filter",
      min = floor(min(obj_space_default_data$dom_crel)),
      max = ceiling(max(obj_space_default_data$dom_crel)),
      value = c(floor(min(obj_space_default_data$dom_crel)),
                ceiling(max(obj_space_default_data$dom_crel))))
  })

  output$obj_space <- renderParcoords({
    #v$reset # take dependency - allows us to redraw everytime reset button is hit.

    id_range <- range(obj_space_disp_data$d$ID)
    id_ticks <- seq(rnd_up(id_range[1], 10), rnd_down(id_range[2], 10), by = 10)

    parcoords(
      obj_space_disp_data$d,
      rownames = FALSE,
      brushMode = "1D-axes",
      brushPredicate = "and",
      reorderable = TRUE,
      alpha = 0.6,
      queue = TRUE,
      rate  = 200,
      color = list(
        colorBy = "cost",
        colorScale = htmlwidgets::JS('
          d3.scale.threshold()
          .domain([200,240,280,320,360,400,440])
          .range(["#feedde","#fdd0a2","#fdae6b","#fd8d3c","#f16913", "d94801"])
          ')
        ),
      #.range(["#f1eef6","#bdc9e1","#74a9cf","#2b8cbe","#045a8d"]) multi-hue blue
      #.range(["#bcbddc","#9e9ac8","#807dba","#6a51a3","#4a1486"]) purple
      #.range(["#feedde","#fdbe85","#fd8d3c","#e6550d","#a63603"]) orange
      dimensions = list(
        ID   = list(title = "ID", tickValues = id_ticks),
        cost = list(title = "Cost"),
        dom_rel = list(title = "Dom. Reliability"),
        irr_rel = list(title = "Irr. Reliability"),
        eco_rel = list(title = "Env. Reliability"),
        dom_crel = list(title = "Dom. Crit. Reliability")
      ),
      tasks = htmlwidgets::JS("function f(){this.parcoords.alphaOnBrushed(0.15);}")
    ) #close parcoords
  })

  # gets the selected lines on the parallel coordinates plot
  obj_space_selected <- reactive({
    ids <- rownames(base_clim) %in% input$obj_space_brushed_row_names
    rows <- obj_space_disp_data$d[ids,] # doesn't have all the columns we need

    ids <- rows$ID
    base_clim[base_clim$ID %in% rows$ID, ]
    #base_clim[ids,]
    #base_clim(base_clim$ID == ids)
  })

  output$dec_space_dt <- DT::renderDataTable(datatable(
    select(obj_space_selected(),
      ID, cost, K, prio, alpha, beta, dom_rel, irr_rel, eco_rel, dom_crel),
    extensions = c('Buttons','Scroller'),
    options = list(
      dom = 'Bfrtip',
      buttons = c('copy', 'excel', 'pdf', 'print'),
      deferRender = TRUE,
      scrollY = 300,
      scrollX = TRUE,
      scroller = TRUE),
    selection = list(mode = 'multiple', selected = c(1)),
    height = 300,
    rownames = FALSE
  ))

  # gets the selected rows in the decision space data table
  dec_space_selected <- reactive({
    ids <- base_clim$ID %in% input$dec_space_dt_rows_selected
    obj_space_selected()[ids,]

  })

  output$design_select_dt <- DT::renderDataTable({
    datatable(
    select(dec_space_selected(),
      ID, cost, K, prio, alpha, beta),
    selection = list(mode = 'none'),
    options = list(
      scrollX = TRUE
    ),
    rownames = FALSE
  )})

  row_ids <- reactive({
    ids <- dec_space_selected()$ID
    print(ids)
    ids
  })

  climate1 <- callModule(climate_robustness,
                         "climate1",
                         id = "climate1",
                         #rows = reactive({input$design_select_dt_rows_all}),
                         rows = row_ids,
                         adap_results = adap_results,
                         dec_space_selected = dec_space_selected,
                         metric_to_plot = reactive({input$metric_select}),
                         CMIP5 = CMIP5)
  climate1 <- callModule(climate_robustness,
                         "climate2",
                         id = "climate2",
                         #rows = reactive({input$design_select_dt_rows_all}),
                         rows = row_ids,
                         adap_results = adap_results,
                         dec_space_selected = dec_space_selected,
                         metric_to_plot = reactive({input$metric_select}),
                         CMIP5 = CMIP5)
}

################################################################################
############################## SERVER ##########################################
################################################################################
