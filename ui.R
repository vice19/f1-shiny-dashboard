library(shiny)

ui = fluidPage(
  titlePanel("🏎️ 2025 Formula One Championship"),

  sidebarLayout(
    sidebarPanel(
      uiOutput("gp_select"),
      uiOutput("driver_select"),
      actionButton("show_driver_btn", "Study a driver",
                   class = "btn-primary btn-block")
    ),
    mainPanel(
      verbatimTextOutput("gp_summary"),
      # verbatimTextOutput("preview"),
      conditionalPanel("input.show_driver_btn > 0", 
                       plotOutput("lap_time_plot"), 
                       radioButtons("lap_time_plot_scale","Choose the scale: ", 
                                    choiceValues = c("Default","Non default"), 
                                    choiceNames = c("Auto-scaled (min to max)","Zero-baseline (0 to max)"))
                       ),
      conditionalPanel("input.show_driver_btn > 0",
                       plotOutput("race_pace_plot"), 
                       radioButtons("race_pace_kernel", "Choose the kernel:",
                                    choiceValues = c("gaussian", "rectangular", "custom"),
                                    choiceNames  = c("Gaussian (Normal)", "Rectangular", "Custom (|u| - Activity 8.1)")),
                       sliderInput("bandwidth","Choose the bandwidth: ", min = 0.01, max = 100, value = 1, step = 0.1)
                       )
    )
  )
)
