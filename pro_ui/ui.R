library(shiny)

ui = fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #f3f4f8;
        font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        color: #1f2430;
      }
      /* Top F1 Telemetry Header */
      .f1-header {
        background: linear-gradient(135deg, #15151e 0%, #252535 100%);
        color: #ffffff;
        padding: 20px 28px;
        margin: -15px -15px 24px -15px;
        border-bottom: 5px solid #e10600;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      }
      .f1-header h2 {
        margin: 0;
        font-weight: 800;
        letter-spacing: 0.5px;
        font-size: 26px;
      }
      .f1-header p {
        margin: 5px 0 0 0;
        color: #b8bcc8;
        font-size: 14px;
      }
      /* Card Containers */
      .f1-card {
        background: #ffffff;
        border-radius: 10px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.06);
        border-top: 3px solid #e10600;
      }
      .f1-card-dark {
        background: #ffffff;
        border-radius: 10px;
        padding: 18px;
        margin-bottom: 20px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.06);
        border-top: 3px solid #15151e;
      }
      .f1-card h4, .f1-card-dark h4 {
        margin-top: 0;
        margin-bottom: 14px;
        font-weight: 700;
        color: #15151e;
        border-bottom: 1px solid #eceef2;
        padding-bottom: 8px;
      }
      /* Primary F1 Action Button */
      #show_driver_btn {
        background-color: #e10600;
        border-color: #c40500;
        color: #ffffff;
        font-weight: 700;
        font-size: 15px;
        padding: 10px 16px;
        border-radius: 6px;
        transition: all 0.2s ease;
        margin-top: 8px;
      }
      #show_driver_btn:hover {
        background-color: #b80500;
        transform: translateY(-1px);
        box-shadow: 0 4px 10px rgba(225, 6, 0, 0.3);
      }
      /* GP Summary Preformatted Box */
      #gp_summary {
        background-color: #1e1e2a;
        color: #f8f9fa;
        border: none;
        border-left: 4px solid #e10600;
        border-radius: 6px;
        padding: 14px;
        font-size: 13.5px;
        line-height: 1.55;
        margin-bottom: 0;
      }
      /* Navigation Pills */
      .nav-pills > li > a {
        border-radius: 6px;
        font-weight: 600;
        color: #15151e;
        background-color: #e4e7ee;
        margin-right: 8px;
        margin-bottom: 14px;
        border: 1px solid #d8dce6;
      }
      .nav-pills > li.active > a,
      .nav-pills > li.active > a:hover,
      .nav-pills > li.active > a:focus {
        background-color: #e10600;
        color: #ffffff;
        border-color: #e10600;
      }
      /* Pedagogical Info Note */
      .info-note {
        background-color: #f8f9fc;
        border-left: 4px solid #15151e;
        padding: 10px 14px;
        border-radius: 4px;
        font-size: 13px;
        color: #4a5060;
        margin-top: 12px;
      }
    "))
  ),

  # --- TOP HEADER BANNER ---
  div(class = "f1-header",
      h2("🏎️ 2025 Formula One World Championship — Telemetry Explorer"),
      p("Interactive Data Visualization: Scale Distortion, Kernel Density Estimation & Simpson's Paradox")
  ),

  fluidRow(
    # ==========================================================
    # LEFT SIDEBAR COLUMN (Width = 3): Controls & GP Summary
    # ==========================================================
    column(
      width = 3,
      div(class = "f1-card",
          h4("🎛️ Race & Driver Selection"),
          uiOutput("gp_select"),
          uiOutput("driver_select"),
          actionButton("show_driver_btn", "🏁 Study a driver",
                       class = "btn-primary btn-block")
      ),
      div(class = "f1-card-dark",
          h4("🏆 Grand Prix Overview"),
          verbatimTextOutput("gp_summary")
      )
    ),

    # ==========================================================
    # RIGHT MAIN COLUMN (Width = 9): Tabbed Interactive Plots
    # ==========================================================
    column(
      width = 9,

      # Placeholder shown before the user clicks "Study a driver"
      conditionalPanel(
        "input.show_driver_btn == 0",
        div(class = "f1-card", style = "text-align: center; padding: 60px 20px;",
            h3("👈 Select a Grand Prix and a Driver"),
            p(style = "color: #6c757d; font-size: 16px;",
              "Click the red 'Study a driver' button in the left panel to load lap-by-lap telemetry, density estimation, and stint analysis.")
        )
      ),

      # Main analysis tabs shown once "Study a driver" is clicked
      conditionalPanel(
        "input.show_driver_btn > 0",
        tabsetPanel(
          type = "pills",

          # ----------------------------------------------------
          # TAB 1: LAP TIME SCATTER PLOT & SCALE DISTORTION
          # ----------------------------------------------------
          tabPanel(
            "📈 1. Lap Times & Scale",
            fluidRow(
              column(
                width = 8,
                div(class = "f1-card",
                    h4("Lap-by-Lap Telemetry & Tyre Strategy"),
                    plotOutput("lap_time_plot", height = "480px")
                )
              ),
              column(
                width = 4,
                div(class = "f1-card-dark",
                    h4("⚙️ Y-Axis Scale Controls"),
                    radioButtons("lap_time_plot_scale", "Choose the scale:",
                                 choiceValues = c("Default", "Non default"),
                                 choiceNames  = c("Auto-scaled (min to max)",
                                                  "Zero-baseline (0 to max)")),
                    div(class = "info-note",
                        tags$b("Why does scale matter?"), br(),
                        "• ", tags$b("Auto-scaled:"), " highlights fine lap-to-lap variations (tyre wear, fuel burn, and Pit/SC outliers).", br(),
                        "• ", tags$b("Zero-baseline:"), " anchors the axis at 0 s, compressing variance and showing how improper scale bounds can hide real trends."
                    )
                )
              )
            )
          ),

          # ----------------------------------------------------
          # TAB 2: RACE PACE KDE & ROBUSTNESS TO CONTAMINATION
          # ----------------------------------------------------
          tabPanel(
            "📊 2. Race Pace Density (KDE)",
            fluidRow(
              column(
                width = 7,
                div(class = "f1-card",
                    h4("Kernel Density Estimation of Lap Times"),
                    plotOutput("race_pace_plot", height = "420px")
                ),
                div(class = "f1-card-dark",
                    h4("📋 Location & Spread: Mean vs Quartiles"),
                    tableOutput("race_pace_stats")
                )
              ),
              column(
                width = 5,
                div(class = "f1-card-dark",
                    h4("⚙️ KDE & Sample Controls"),
                    radioButtons("race_pace_kernel", "Choose the kernel:",
                                 choiceValues = c("gaussian", "rectangular", "custom"),
                                 choiceNames  = c("Gaussian (Normal)",
                                                  "Rectangular",
                                                  "Custom (|u| - Activity 8.1)")),
                    hr(),
                    radioButtons("bw_method", "Automatic bandwidth selector:",
                                 choiceValues = c("SJ", "nrd0"),
                                 choiceNames  = c("Sheather-Jones (bw.SJ)",
                                                  "Silverman Rule-of-Thumb (bw.nrd0)")),
                    sliderInput("bandwidth", "Bandwidth multiplier (adjust):",
                                min = 0.1, max = 3, value = 1, step = 0.1),
                    hr(),
                    checkboxInput("show_individual_kernels",
                                  "Show individual kernel contributions (Teaching View)",
                                  value = FALSE),
                    checkboxInput("include_contamination",
                                  "Include Pit/SC/VSC laps (Contaminated Sample)",
                                  value = FALSE),
                    div(class = "info-note",
                        tags$b("Outlier Contamination:"), br(),
                        "Toggling Pit/SC/VSC laps adds extreme right-tail outliers (~110–150 s). Notice how ",
                        tags$code("bw.nrd0"), " oversmooths the main race pace peak compared to ",
                        tags$code("bw.SJ"), ", and how the ", tags$b("Mean"),
                        " shifts much more than the ", tags$b("Quartiles (Q1, Median, Q3)"), "."
                    )
                )
              )
            )
          ),

          # ----------------------------------------------------
          # TAB 3: SIMPSON'S PARADOX (OVERALL VS STINTS)
          # ----------------------------------------------------
          tabPanel(
            "🔄 3. Simpson's Paradox (Stints)",
            fluidRow(
              column(
                width = 8,
                div(class = "f1-card",
                    h4("Overall Normal Laps vs Individual Tyre Stints (Lap > 1)"),
                    plotOutput("simpson_plot", height = "580px")
                )
              ),
              column(
                width = 4,
                div(class = "f1-card-dark",
                    h4("⚙️ Regression & Correlations"),
                    checkboxInput("show_simpson_lm",
                                  "Show linear regression lines (lm)",
                                  value = FALSE),
                    tableOutput("simpson_table"),
                    div(class = "info-note",
                        tags$b("Simpson's Paradox in F1:"), br(),
                        "• ", tags$b("Overall:"), " cars burn ~100 kg of fuel during the race and switch to fresh tyres at pit stops, often making lap times decrease overall (negative correlation).", br(),
                        "• ", tags$b("Within Stints:"), " on the same set of tyres, progressive rubber degradation often causes lap times to increase (positive correlation)."
                    )
                )
              )
            )
          )
        )
      )
    )
  )
)
