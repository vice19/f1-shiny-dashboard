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
                       radioButtons("lap_time_plot_scale", "Choose the scale: ", 
                                    choiceValues = c("Default", "Non default"), 
                                    choiceNames  = c("Auto-scaled (min to max)", "Zero-baseline (0 to max)"))
                       ),
      conditionalPanel("input.show_driver_btn > 0",
                       plotOutput("race_pace_plot"), 
                       radioButtons("race_pace_kernel", "Choose the kernel:",
                                    choiceValues = c("gaussian", "rectangular", "custom"),
                                    choiceNames  = c("Gaussian (Normal)", "Rectangular", "Custom (|u| - Activity 8.1)")),
                       radioButtons("bw_method", "Automatic bandwidth selector:",
                                    choiceValues = c("SJ", "nrd0"),
                                    choiceNames  = c("Sheather-Jones (bw.SJ)", "Silverman Rule-of-Thumb (bw.nrd0)")),
                       sliderInput("bandwidth", "Choose the bandwidth multiplier (adjust): ", min = 0.1, max = 3, value = 1, step = 0.1),
                       checkboxInput("show_individual_kernels", "Show individual kernel contributions (Teaching View)", value = FALSE),
                       checkboxInput("include_contamination", "Include Pit/SC/VSC laps (Contaminated sample)", value = FALSE)
                       )
    )
  )
)
