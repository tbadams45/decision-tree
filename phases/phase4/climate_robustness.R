climate_robustnessUI <- function(id) {
  ns <- NS(id)

  fluidPage(
    fluidRow(column(6, uiOutput(ns(
      "design_select_ui")))
    ), # closs fluidRow for inputs
    plotOutput(ns("heatmap"), height = "350px", width = "425px"),
    br(),
    checkboxGroupInput(
      ns("climInfo"),
      label = "Display climate information",
      inline = F,
      c(
        "Historical climate (1960-2000)" = 1,
        "CMIP5 projections"              = 2,
        "CMIP5 confidence level (95%)"   = 3,
        "CMIP5 confidence level (99%)"   = 4
      )
    ),
    bsTooltip(
      ns("climInfo"),
      "Information to evaluate the subjective likelihood of climate changes",
      placement = "bottom",
      options = list(container = "body")
    )
  )
}

climate_robustness <- function(input,
                               output,
                               session,
                               id,
                               rows,                 # list - ids of designs
                               adap_results,         # data frame
                               dec_space_selected,   # reactive
                               metric_to_plot,       # character
                               CMIP5) {

  output$design_select_ui <- renderUI({
    selectInput(session$ns("design_selection"), label = h5("ID of the decision set you'd like to examine."),
      choices = rows())
  })

  heatmap_data <- reactive({
    req(input$design_selection)

    index <- as.numeric(input$design_selection)
    row   <- dec_space_selected()[dec_space_selected()$ID == index,]

    results <- adap_results %>%
      filter(prio  == row$prio   &
          alpha == row$alpha  &
          beta  == row$beta   &
          K     == row$K)
    results
  })

  output$heatmap <- renderPlot({

    #need one set of temp/precip data.
    df   <- heatmap_data()
    if(nrow(df) == 0){
      # this prevents an error from showing up whenever we reselect something on
      # parcoords
    } else {
      plot <- climate_heatmap(df,
        metric = get_metric(metric_to_plot()),
        metricCol = metric_to_plot(),
        binary = FALSE)

      if(1 %in% input$climInfo) {
        plot <- plot + geom_vline(xintercept = 0, linetype = "dashed", size = 1) +
          geom_hline(yintercept = 1, linetype = "dashed", size = 1)
      }
      if(2 %in% input$climInfo) {
        plot <- plot + geom_point(aes(x = del_temp, y = del_prec, shape = Scenario),
          size = 2, data = CMIP5, stroke = 1.5) +
          scale_shape_manual(name = "Scenarios", values =c(21,22,23,24))
      }
      if(3 %in% input$climInfo) {
        plot <- plot + stat_ellipse(aes(x = del_temp, y = del_prec), data = CMIP5,
          size = 1, linetype = "dotdash", level = 0.95)
      }
      if(4 %in% input$climInfo) {
        plot <- plot + stat_ellipse(aes(x = del_temp, y = del_prec), data = CMIP5,
          size = 1, linetype = "dotdash", level = 0.99)
      }

      plot
    }
  })
}



################################################################################
############################ UTIL FUNCTIONS ####################################
################################################################################

get_metric <- function(key){
  if (key == "dom_rel" || key == "irr_rel" || key == "eco_rel" ||
      key == "dom_crel" || key == "irr_crel" || key == "eco_crel"){
    return("reliability")
  } else if (key == "dom_res" || key == "irr_res" || key == "eco_res") {
    return("resilience")
  } else if (key == "dom_vul" || key == "irr_vul" || key == "eco_vul") {
    return("vulnerability")
  } else {
    stop("Error in get_metric: not a valid key")
  }
}

