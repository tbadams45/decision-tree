
source("phases/utils.R", local = TRUE)

################################################################################
################################  UI  ##########################################
################################################################################

phase3UI <- function(id) {
  ns <- NS(id)

  size_min_res     <- 50  # minimum size of reservoir in dam
  size_max_res     <- 110 # max size of reservoir in dam
  size_inc_res     <- 10  # resolution of reservoir size analysis.
  size_default_res <- 80 # default reservoir size (when app is first opened)

  tabsetPanel(

    # surface plot
    tabPanel("Climate Only", value = ns("climate_only"),
      fluidPage(
        box(title = strong("Settings"), width=4, status="primary",
          fluidRow(tags$div(style="margin-left:15px;",
            bsButton(inputId = ns("SurfaceReset"), label="Defaults",
              icon = icon(name="refresh")))
          ), #fluidrow close
          br(),
          div(id = ns("SurfaceInputs"),
            wellPanel(
              em(strong(helpText(span("Performance assessment",
                style="color:blue")))),
              radioButtons(inputId = ns("metric"), label="Metric",
                selected="reliability", inline=T,
                choices = c("safeyield", "reliability")),
              bsTooltip(ns("metric"),
                "safeyield in MCM, reliability as %",
                placement = "right", options = list(container = "body")),
              radioButtons(inputId = ns("units"), label="Evaluation type",
                selected = "disabled", inline = T,
                choices = c("Continuous"="disabled", "binary"="enabled")),
              bsTooltip(ns("units"), "Reporting method of the metric",
                placement = "right", options = list(container = "body")),
              sliderInput(inputId = ns("threshold"), label = "Threshold",
                min = 80, max = 100, step = 1, value = 90, ticks = F),
              bsTooltip(ns("threshold"), "performance threshold (for binary evaluation)",
                placement = "right", options = list(container = "body"))
            ), # welpanel close
            wellPanel(
              em(strong(helpText(span("Natural climate variability",
                style="color:blue")))),
              radioButtons(inputId=ns("dataset"), label="Underlying data",
                choices = c("Princeton","GPCC","CRU"), selected="Princeton",
                inline = T),
              bsTooltip(ns("dataset"),
                "climate data used to generate stochastic realizations",
                placement = "right", options = list(container = "body")),
              h5(strong("Climate realization")),
              checkboxInput(ns("meanTrace"), "Mean realization", value = T),
              #condition=paste0("input.", ns("meanTrace"), "== 0"),
              bsTooltip(ns("meanTrace"),
                "show results for the mean of all traces or for an individual trace",
                placement = "right", options = list(container = "body")),
              sliderInput(ns("nvar"), label = NULL,
                min=1, max=10, step=1, value=1, ticks=F)
            ), # wellpanel close
            wellPanel(
              em(strong(helpText(span("Non-climatic attributes",
                style = "color:blue")))),

              #conditionalPanel(
              #  condition="input.metric == 'reliability'",
              sliderInput(ns("demand"), "Demand increase",
                min = 30, max = 105, step = 15, value = 75, post="%", ticks = F),
              bsTooltip(ns("demand"),
                "Increase in demand relative to the 2015 level (38 MCM/year)",
                placement = "right", options = list(container = "body")),
              sliderInput(ns("size"), "Reservoir size",
                min = size_min_res, max = size_max_res, step = size_inc_res,
                value = size_default_res, post="MCM", ticks = F),
              bsTooltip(ns("size"),
                "Reservoir storage capacity",
                placement = "right", options = list(container = "body"))
            ) # wellpanel close
          ) # div close
        ), #box close
        box(title = strong("Climate response surface"), width=8,
          align = "left", status="primary",
          plotOutput(ns("SurfacePlot"), height = "500px", width = "600px", click = clickOpts(id = ns("surface_click"))),
          br(),
          checkboxGroupInput(ns("climInfo"), label="Display climate information",
            inline=F,
            c("Historical climate (1960-2000)"=1,
              "CMIP5 projections"=2,
              "CMIP5 confidence level (95%)"=3,
              "CMIP5 confidence level (99%)"=4)),
          htmlOutput(ns("surface_click_info")),
          bsTooltip(ns("climInfo"),
            "Information to evaluate the subjective likelihood of climate changes",
            placement = "bottom", options = list(container = "body"))
        ) #box close
      ) #fluidpage close

    ), # close tabPanel

    # parallel coordinates plot
    tabPanel("Multivariate", value = ns("multivariate"),
      fluidPage(
        box(title = strong("Settings"), width = 3, solidHeader=F,
          status="primary",
          wellPanel(
            em(strong(helpText(span("Design features", style = "color:blue")))),
            sliderInput(ns("ParcoordSizeSelect"), "Reservoir size",
              min = size_min_res, max = size_max_res, step = size_inc_res,
              value = size_default_res, post="MCM", ticks=F)
          ),
          wellPanel(
            em(strong(helpText(span("Scenario definition",
              style = "color:blue")))),
            numericInput(inputId = ns("ParCoordThold"), label = "NPV Threshold",
              min = 500, max = 2000, value = 1000),
            selectInput(inputId = ns("ParCoordTholdType"), label = "Threshold type",
              choices=c(">=","<="), selected = ">=", selectize = F)
          ) #wellPanel close
        ), #box close
        box(title = strong("Vulnerability domain"), width = 9, align = "left",
          solidHeader = F, status = "primary",
          parcoordsOutput(ns("ParcoordPlot")),
          valueBoxOutput(ns("range"), width=4),
          valueBoxOutput(ns("coverage"), width=4),
          valueBoxOutput(ns("density"), width=4),
          br(), br(),
          plotOutput(ns("npv_distribution"), height = "300px", width = "500px"),
          br(), br(), br(), br(),
          #Tooltips
          bsTooltip(ns("coverage"),
            "the percentage of satisfying runs that are described by the selection",
            placement = "bottom", options = list(container = "body")),
          bsTooltip(ns("density"),
            "the percentage of satisfying runs within the selection",
            placement = "bottom", options = list(container = "body")),
          bsTooltip(ns("range"),
            "relative size of the selection compared to the total number of lines on the plot",
            placement = "bottom", options = list(container = "body"))
        ) #box close
      ) #fluidpage close
    ) #close tabPanel
  ) # close tabsetPanel
}



################################################################################
############################## SERVER ##########################################
################################################################################

phase3 <- function(input, output, session, surface_data, parc_data) {
  # RESPONSE SURFACES ------------------------------------------------------------

  # Graphical parameters for surface plot
  label <- list(
    x = expression("Temperature change (" * degree * C *")"),
    y = paste("Precipitation change (%)"))

  tick <- list(x = seq(0,5,1), y = seq(0.7,1.5,0.1))
  lim  <- list(x = c(-0.5,5.5), y = c(0.65,1.55))

  font_size <- 14

  theme_set(theme_bw(base_size = font_size))
  theme_update(
    plot.title    = element_text(face = "bold"),
    panel.border  = element_rect(color = "black", fill = NA),
    legend.text   = element_text(size=font_size-2),
    legend.title  = element_text(size=font_size-2)
  )

  #### SURFACEPLOT DATA ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  surfaceData <- reactive({
    var <- input$metric

    dat <- surface_data %>% rename_(value = var) %>%
      filter(dataset==input$dataset & size==input$size & demand==input$demand)

    #Plot for the mean trace
    if(input$meanTrace == 1) {
      dat %<>% filter(nvar == 0)} else {dat %<>% filter(nvar == input$nvar)}

    #Threshold based evaluation
    if(input$units == "enabled") {
      var_col <- c("royalblue4", "firebrick2")
      threshold <- ifelse(is.null(input$threshold),90,input$threshold)
      dat <- mutate(dat,
        Bins=ifelse(value>=threshold, "Acceptable", "Not acceptable"),
        Bins=factor(Bins, levels = c("Acceptable", "Not acceptable"),
          labels = c("Acceptable", "Not acceptable")))

      #In absolute units
    } else {
      if (var == "reliability") {

        bin1 <- c(seq(40,90,10),95)
        bin2 <- seq(96,100,1)
        col1 <- colorRampPalette(c("firebrick2", "white"))(length(bin1))
        col2 <- colorRampPalette(c("lightsteelblue1", "royalblue4"))(length(bin2))
        var_col <- c(col1,col2)
        var_bin <- c(bin1, bin2)

      } else {

        bin1 <- seq(30,80,10)
        bin2 <- seq(90,130,10)
        col1 <- colorRampPalette(c("firebrick2", "white"))(length(bin1))
        col2 <- colorRampPalette(c("lightsteelblue1", "royalblue4"))(length(bin2))
        var_col <- c(col1,col2)
        var_bin <- c(bin1, bin2)

      }

      dat <- mutate(dat, Bins = cut(value,
        breaks = var_bin, dig.lab = 5, include.lowest = T))
    }

    list(dat = dat, var_col = var_col)
  })

  SurfacePlot <- reactive({
    df   <- surfaceData()$dat
    varcols <- surfaceData()$var_col

    p1 <- ggplot(data = df, aes(x = temp, y = prec)) +
      geom_tile(aes(fill = Bins), color = "gray60") +
      scale_x_continuous(expand=c(0,0), breaks = tick$x) +
      scale_y_continuous(expand=c(0,0), breaks = tick$y,
        labels = seq(-30, +50, 10)) +
      scale_fill_manual(name = "Range", values = varcols, drop = FALSE)  +
      guides(fill = guide_legend(order = 1, keyheight = 1.5, keywidth = 1.5),
        shape = guide_legend(order = 2, keyheight = 1.5, keywidth = 1.5)) +
      labs(x = label$x, y = label$y)

    if(1 %in% input$climInfo) {
      p1 <- p1 + geom_vline(xintercept = 0, linetype = "dashed", size = 1) +
        geom_hline(yintercept = 1, linetype = "dashed", size = 1)
    }
    if(2 %in% input$climInfo) {
      p1 <- p1 + geom_point(aes(x = del_temp, y = del_prec, shape = Scenario),
        size = 2, data = CMIP5, stroke = 1.5) +
        scale_shape_manual(name = "Scenarios", values =c(21,22,23,24))
    }
    if(3 %in% input$climInfo) {
      p1 <- p1 + stat_ellipse(aes(x = del_temp, y = del_prec), data = CMIP5,
        size = 1, linetype = "dotdash", level = 0.95)
    }
    if(4 %in% input$climInfo) {
      p1 <- p1 + stat_ellipse(aes(x = del_temp, y = del_prec), data = CMIP5,
        size = 1, linetype = "dotdash", level = 0.99)
    }

    p1
  })
  #output$SurfacePlot <- renderPlotly({SurfacePlot()})
  output$SurfacePlot <- renderPlot({SurfacePlot()})

  #### DYNAMIC METRIC SELECTION BUTTONS +++++++++++++++++++++++++++++++++++++++++
  observeEvent(input$SurfaceReset, {shinyjs::reset("SurfaceInputs")})

  observe({
    if (input$metric == "reliability") {
      shinyjs::enable("demand")
      if (input$units=='enabled') {
        updateSliderInput(session, inputId = "threshold", label = "Threshold",
          min = 80, max = 100, step = 1, value = 90)}
    } else if (input$metric == "safeyield") {
      shinyjs::disable("demand")
      if (input$units=="enabled") {
        updateSliderInput(session, inputId = "threshold", label = "Threshold",
          min = 40, max = 140, step = 5, value = 100)}
    }
  })

  observe({
    if (input$units=='enabled')
      shinyjs::enable("threshold")
    else
      shinyjs::disable("threshold")
  })

  observe({
    if (input$meanTrace == 0) {
      shinyjs::enable("nvar")
    }
    else {
      shinyjs::disable("nvar")
    }
  })


  #### Interaction with heatmap/surface plot -----------------------------------

  output$surface_click_info <- renderUI({
    req(input$surface_click$x, input$surface_click$y)

    x <- rnd(input$surface_click$x, nearest = 1)
    y <- rnd(input$surface_click$y, nearest = 0.1)
    oldData <- filter(surfaceData()$dat)
    data <- filter(surfaceData()$dat, temp == round(x, 0), prec == round(y, 1))
    metric <- cap_first(input$metric)
    HTML(paste0("<div class = 'surface-plot-click-info'>", "Values for selected box: <br>", "Temperature increase: ", data$temp, " &#8451;",
      "<br> Precipitation Change: ", data$prec*100, "% <br>", metric, ": ", round(data$value, 2), "</div>"))
  })



  # MULTIVARIATE ANALYSIS ------------------------------------------------------
  parcoord_data <- reactive({
    parc_data %>%
      filter(size == as.numeric(input$ParcoordSizeSelect)) %>%
      select(#"realization" = var,
        "delta Temp" = dtemp,
        "delta Prec" = dprec,
        "price" = prc,
        "demand" = dem,
        "sediment" = sed,
        "disc rate" = dsc,
        "NPV" = NPV)
  })

  ####### PARALEL COORDINATES PLOT
  output$ParcoordPlot <- renderParcoords({
    parcoords(
      data = parcoord_data(),
      rownames = F,
      brushMode = "1D-axes",
      brushPredicate = "and",
      reorderable = T,
      axisDots = NULL,
      composite = NULL,
      margin = list(top = 20, left = 0, bottom = 50, right = 0),
      alpha = 0.3,
      queue = T,
      rate = 200,
      color = "steelblue",
      #color = list(
      #  colorBy = "NPV",
      #  colorScale = htmlwidgets::JS(sprintf('
      #  d3.scale.threshold()
      #    .domain(%s)
      #    .range(%s)
      #  ',
      #    jsonlite::toJSON(seq(0,round(max(parcoord_data()$NPV)))),
      #    jsonlite::toJSON(RColorBrewer::brewer.pal(6,"PuBuGn"))
      #  ))
      #),
      tasks = htmlwidgets::JS("function foo(){this.parcoords.alphaOnBrushed(0.15);}")
    )
  })


  pc_data_selected <- reactive({
    ids <- rownames(parcoord_data()) %in% input$ParcoordPlot_brushed_row_names
    rows <- parcoord_data()[ids,]
    rows
  })


  ####### NPV histogram - show distribution of selected area.
  output$npv_distribution <- renderPlot({
    req(input$ParCoordThold, nrow(pc_data_selected()) != 0)
    pc_data <- parcoord_data()
    pc_data$data <- 'All'
    pc_selected  <- pc_data_selected()
    pc_selected$data <- 'Selected'

    histo_data <- rbind(pc_data, pc_selected)

    ggplot(histo_data, aes(NPV)) +
      geom_histogram(data = filter(histo_data, data == 'All'), binwidth = 80, color = "red", alpha = 0.2) +
      geom_histogram(data = filter(histo_data, data == 'Selected'), binwidth = 80, color = "blue", alpha = 0.2) +
      geom_vline(xintercept = input$ParCoordThold, colour = "red") +
      theme_tufte(base_size = 14, base_family = 'GillSans') +
      coord_flip() +
      theme(axis.title.y = element_text(angle = 0))
  })

  ####### VALUE BOXES
  MvarInfo <- reactive({
    df <- parcoord_data()
    rows <- if(length(input$ParcoordPlot_brushed_row_names) > 0) {
      as.numeric(input$ParcoordPlot_brushed_row_names)
    } else {as.numeric(rownames(df))}

    values <- as.numeric(df[['NPV']])

    val_interest <- switch(input$ParCoordTholdType,
      ">=" = {which(values >= input$ParCoordThold)},
      "<=" = {which(values <= input$ParCoordThold)})

    val_interest_select <- intersect(val_interest, rows)

    cov  <- round(length(val_interest_select) / length(val_interest) * 100)
    den  <- round(length(val_interest_select) / length(rows) * 100)
    size <- round(length(rows)/nrow(df) * 100)

    list(range = valueBox(paste0(size,"%"), "selection range", color="blue"),
      coverage = valueBox(paste0(cov,"%"), "scenario coverage", color="olive"),
      density  = valueBox(paste0(den,"%"), "scenario density", color="maroon"))

  })

  output$range    <- renderValueBox({MvarInfo()[['range']]})
  output$coverage <- renderValueBox({MvarInfo()[['coverage']]})
  output$density  <- renderValueBox({MvarInfo()[['density']]})
}
