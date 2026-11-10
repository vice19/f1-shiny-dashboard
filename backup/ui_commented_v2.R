library(shiny)

# ============================================================
# UI (Version 2)
# Defines the user interface of the 2025 F1 Shiny Application.
# Uses a sidebarLayout with dynamic selectors on the left and
# three interactive analysis sections in the main panel on the right.
# ============================================================
ui = fluidPage(
  titlePanel("🏎️ 2025 Formula One Championship"),

  sidebarLayout(

    # ------------------------------------------------------------
    # SIDEBAR PANEL: Global Filters & Action Trigger
    # ------------------------------------------------------------
    sidebarPanel(
      # Dynamic Grand Prix selector (rendered in server.R)
      uiOutput("gp_select"),

      # Dynamic Driver selector filtered by the chosen GP (rendered in server.R)
      uiOutput("driver_select"),

      # Action button that triggers eventReactive(input$show_driver_btn, ...)
      # and reveals the conditional panels in the main area
      actionButton("show_driver_btn", "Study a driver",
                   class = "btn-primary btn-block")
    ),

    # ------------------------------------------------------------
    # MAIN PANEL: GP Summary & Interactive Visualizations
    # ------------------------------------------------------------
    mainPanel(
      # Always visible: displays GP metadata (round, circuit, date) and Top-3 podium
      verbatimTextOutput("gp_summary"),

      # ==========================================================
      # SECTION 1: Lap-by-Lap Scatter Plot & Y-Axis Scale Distortion
      # Appears once "Study a driver" has been clicked at least once.
      # ==========================================================
      conditionalPanel("input.show_driver_btn > 0", 
                       plotOutput("lap_time_plot"), 
                       radioButtons("lap_time_plot_scale", "Choose the scale: ", 
                                    choiceValues = c("Default", "Non default"), 
                                    choiceNames  = c("Auto-scaled (min to max)", "Zero-baseline (0 to max)"))
                       ),

      # ==========================================================
      # SECTION 2: Race Pace Kernel Density Estimation (KDE)
      # Allows interactive exploration of:
      # - Kernel shape (Gaussian, Rectangular, Custom |u| from Activity 8.1)
      # - Automatic bandwidth rule (Sheather-Jones bw.SJ vs Silverman bw.nrd0)
      # - Bandwidth multiplier slider (adjust)
      # - Teaching View: individual kernel contributions
      # - Contamination toggle (Normal laps only vs All laps with Pit/SC/VSC)
      # - Summary table comparing Mean vs Quartiles (Q1, Median, Q3, IQR)
      # ==========================================================
      conditionalPanel("input.show_driver_btn > 0",
                       plotOutput("race_pace_plot"), 
                       radioButtons("race_pace_kernel", "Choose the kernel:",
                                    choiceValues = c("gaussian", "rectangular", "custom"),
                                    choiceNames  = c("Gaussian (Normal)", "Rectangular", "Custom (|u| - Activity 8.1)")),
                       radioButtons("bw_method", "Automatic bandwidth selector:",
                                    choiceValues = c("SJ", "nrd0"),
                                    choiceNames  = c("Sheather-Jones (bw.SJ)", "Silverman Rule-of-Thumb (bw.nrd0)")),
                       sliderInput("bandwidth", "Choose the bandwidth multiplier (adjust): ", min = 0.1, max = 3, value = 1, step = 0.1),
                       checkboxInput("show_individual_kernels", "Show individual kernel contributions", value = FALSE),
                       checkboxInput("include_contamination", "Include Pit/SC/VSC laps", value = FALSE),
                       tableOutput("race_pace_stats")
                       ),

      # ==========================================================
      # SECTION 3: Simpson's Paradox (Overall vs Stint-by-Stint)
      # - Multi-panel plot: Overall Normal Laps + 1 subplot per tyre stint
      # - Checkbox to overlay linear regression lines (lm)
      # - Summary table of Pearson correlations (Overall vs each Stint)
      # ==========================================================
      conditionalPanel("input.show_driver_btn > 0",
                       plotOutput("simpson_plot", height = "550px"),
                       checkboxInput("show_simpson_lm", "Show linear regression lines (lm)", value = FALSE),
                       tableOutput("simpson_table")
                       )
    )
  )
)
