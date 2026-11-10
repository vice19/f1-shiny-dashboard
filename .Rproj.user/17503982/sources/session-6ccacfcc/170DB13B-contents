library(shiny)

ui = fluidPage(
  tags$head(
    tags$style(HTML("
      /* ==========================================================
         UI MODE SWITCHER BAR (Always visible at top-right)
         ========================================================== */
      .ui-switcher-bar {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        padding: 8px 0;
        gap: 8px;
      }
      .ui-switcher-label {
        font-size: 13px;
        font-weight: 600;
        color: #555;
      }
      body.pro-mode .ui-switcher-label {
        color: #e0e4f0;
      }
      .btn-ui-mode {
        border: 1px solid #ccc;
        background: #fff;
        color: #333;
        padding: 5px 12px;
        font-size: 12.5px;
        font-weight: 600;
        border-radius: 20px;
        cursor: pointer;
        transition: all 0.2s ease;
      }
      .btn-ui-mode.active-mode {
        background: #e10600;
        color: #fff;
        border-color: #e10600;
        box-shadow: 0 2px 6px rgba(225, 6, 0, 0.35);
      }

      /* ==========================================================
         CLASSIC MODE STYLES (Default Shiny look, vertical stack)
         ========================================================== */
      body.classic-mode .pro-only {
        display: none !important;
      }
      body.classic-mode .classic-only {
        display: block !important;
      }
      body.classic-mode .classic-well {
        min-height: 20px;
        padding: 19px;
        margin-bottom: 20px;
        background-color: #f5f5f5;
        border: 1px solid #e3e3e3;
        border-radius: 4px;
        box-shadow: inset 0 1px 1px rgba(0,0,0,.05);
      }
      body.classic-mode .pro-tab-section {
        display: block !important;
        margin-bottom: 25px;
      }

      /* ==========================================================
         PRO DASHBOARD MODE STYLES (F1 Telemetry Theme + Tabs)
         ========================================================== */
      body.pro-mode {
        background-color: #f3f4f8;
        font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        color: #1f2430;
      }
      body.pro-mode .classic-only {
        display: none !important;
      }
      body.pro-mode .pro-only {
        display: block !important;
      }
      body.pro-mode .f1-header {
        background: linear-gradient(135deg, #15151e 0%, #252535 100%);
        color: #ffffff;
        padding: 18px 28px;
        margin: -15px -15px 24px -15px;
        border-bottom: 5px solid #e10600;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        display: flex !important;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
      }
      body.pro-mode .f1-header h2 {
        margin: 0;
        font-weight: 800;
        letter-spacing: 0.5px;
        font-size: 25px;
      }
      body.pro-mode .f1-header p {
        margin: 4px 0 0 0;
        color: #b8bcc8;
        font-size: 13.5px;
      }
      body.pro-mode .f1-card {
        background: #ffffff;
        border-radius: 10px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.06);
        border-top: 3px solid #e10600;
      }
      body.pro-mode .f1-card-dark {
        background: #ffffff;
        border-radius: 10px;
        padding: 18px;
        margin-bottom: 20px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.06);
        border-top: 3px solid #15151e;
      }
      body.pro-mode #show_driver_btn {
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
      body.pro-mode #show_driver_btn:hover {
        background-color: #b80500;
        transform: translateY(-1px);
        box-shadow: 0 4px 10px rgba(225, 6, 0, 0.3);
      }
      body.pro-mode #gp_summary {
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
      /* Pro Mode Side-by-Side Flex Layout inside each Tab */
      body.pro-mode .pro-split-row {
        display: flex;
        gap: 20px;
        align-items: flex-start;
      }
      body.pro-mode .pro-col-plot {
        flex: 1 1 65%;
        min-width: 0;
      }
      body.pro-mode .pro-col-controls {
        flex: 1 1 35%;
        min-width: 260px;
      }
      @media (max-width: 992px) {
        body.pro-mode .pro-split-row {
          flex-direction: column;
        }
        body.pro-mode .pro-col-plot,
        body.pro-mode .pro-col-controls {
          width: 100%;
        }
      }
      /* Pro Mode Custom Tab Pills */
      .pro-tabs-nav {
        display: flex;
        gap: 10px;
        margin-bottom: 18px;
        flex-wrap: wrap;
      }
      .pro-tab-btn {
        border: 1px solid #d8dce6;
        background-color: #e4e7ee;
        color: #15151e;
        font-weight: 600;
        padding: 10px 18px;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.15s ease;
      }
      .pro-tab-btn.active-tab {
        background-color: #e10600;
        color: #ffffff;
        border-color: #e10600;
        box-shadow: 0 2px 8px rgba(225, 6, 0, 0.25);
      }
      body.pro-mode .pro-tab-section {
        display: none;
      }
      body.pro-mode .pro-tab-section.active-tab-pane {
        display: block;
      }
      .pro-card-title {
        margin-top: 0;
        margin-bottom: 14px;
        font-weight: 700;
        color: #15151e;
        border-bottom: 1px solid #eceef2;
        padding-bottom: 8px;
      }
      .info-note {
        background-color: #f8f9fc;
        border-left: 4px solid #15151e;
        padding: 10px 14px;
        border-radius: 4px;
        font-size: 13px;
        color: #4a5060;
        margin-top: 12px;
      }
    ")),
    tags$script(HTML("
      function setUiMode(mode) {
        document.body.classList.remove('classic-mode', 'pro-mode');
        document.body.classList.add(mode + '-mode');
        document.querySelectorAll('.btn-ui-mode').forEach(function(btn) {
          btn.classList.toggle('active-mode', btn.getAttribute('data-mode') === mode);
        });
        if (window.jQuery) {
          $('.shiny-bound-output').trigger('shown');
        }
        window.dispatchEvent(new Event('resize'));
      }
      function setProTab(tabId) {
        document.querySelectorAll('.pro-tab-section').forEach(function(sec) {
          sec.classList.toggle('active-tab-pane', sec.id === tabId);
        });
        document.querySelectorAll('.pro-tab-btn').forEach(function(btn) {
          btn.classList.toggle('active-tab', btn.getAttribute('data-target') === tabId);
        });
        if (window.jQuery) {
          $('.shiny-bound-output').trigger('shown');
        }
        window.dispatchEvent(new Event('resize'));
      }
      document.addEventListener('DOMContentLoaded', function() {
        setUiMode('pro');
      });
    "))
  ),

  # --- CLASSIC MODE HEADER + SWITCHER ---
  div(class = "classic-only",
      div(style = "display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap;",
          h2("🏎️ 2025 Formula One Championship"),
          div(class = "ui-switcher-bar",
              span(class = "ui-switcher-label", "🎨 View Mode:"),
              tags$button(class = "btn-ui-mode", `data-mode` = "classic",
                          onclick = "setUiMode('classic')", "Classic UI"),
              tags$button(class = "btn-ui-mode active-mode", `data-mode` = "pro",
                          onclick = "setUiMode('pro')", "🏎️ Pro Dashboard")
          )
      )
  ),

  # --- PRO DASHBOARD HEADER + SWITCHER ---
  div(class = "f1-header pro-only",
      div(
        h2("🏎️ 2025 Formula One World Championship — Telemetry Explorer"),
        p("Interactive Data Visualization: Scale Distortion, Kernel Density Estimation & Simpson's Paradox")
      ),
      div(class = "ui-switcher-bar",
          span(class = "ui-switcher-label", "🎨 View Mode:"),
          tags$button(class = "btn-ui-mode", `data-mode` = "classic",
                      onclick = "setUiMode('classic')", "Classic UI"),
          tags$button(class = "btn-ui-mode active-mode", `data-mode` = "pro",
                      onclick = "setUiMode('pro')", "🏎️ Pro Dashboard")
      )
  ),

  sidebarLayout(
    # ==========================================================
    # SIDEBAR PANEL (Left Column)
    # ==========================================================
    sidebarPanel(
      width = 3,
      style = "background: transparent; border: none; box-shadow: none; padding: 0;",
      div(class = "classic-well f1-card",
          h4(class = "pro-only pro-card-title", "🎛️ Race & Driver Selection"),
          uiOutput("gp_select"),
          uiOutput("driver_select"),
          actionButton("show_driver_btn", "Study a driver",
                       class = "btn-primary btn-block")
      )
    ),

    # ==========================================================
    # MAIN PANEL (Right Column)
    # ==========================================================
    mainPanel(
      width = 9,

      # 1. GP Summary Card
      div(class = "f1-card-dark",
          h4(class = "pro-only pro-card-title", "🏆 Grand Prix Overview"),
          verbatimTextOutput("gp_summary")
      ),

      # Pro-mode navigation pills (visible once "Study a driver" is clicked)
      conditionalPanel(
        "input.show_driver_btn > 0",
        div(class = "pro-only",
            div(class = "pro-tabs-nav",
                tags$button(class = "pro-tab-btn active-tab", `data-target` = "tab-lap",
                            onclick = "setProTab('tab-lap')", "📈 1. Lap Times & Scale"),
                tags$button(class = "pro-tab-btn", `data-target` = "tab-kde",
                            onclick = "setProTab('tab-kde')", "📊 2. Race Pace Density (KDE)"),
                tags$button(class = "pro-tab-btn", `data-target` = "tab-simpson",
                            onclick = "setProTab('tab-simpson')", "🔄 3. Simpson's Paradox (Stints)")
            )
        )
      ),

      # ========================================================
      # SECTION 1: LAP TIME SCATTER PLOT & SCALE DISTORTION
      # ========================================================
      conditionalPanel(
        "input.show_driver_btn > 0",
        div(id = "tab-lap", class = "pro-tab-section active-tab-pane",
            div(class = "pro-split-row",
                div(class = "pro-col-plot f1-card",
                    h4(class = "pro-only pro-card-title", "Lap-by-Lap Telemetry & Tyre Strategy"),
                    plotOutput("lap_time_plot", height = "460px")
                ),
                div(class = "pro-col-controls f1-card-dark",
                    h4(class = "pro-only pro-card-title", "⚙️ Y-Axis Scale Controls"),
                    radioButtons("lap_time_plot_scale", "Choose the scale: ",
                                 choiceValues = c("Default", "Non default"),
                                 choiceNames  = c("Auto-scaled (min to max)", "Zero-baseline (0 to max)")),
                    div(class = "pro-only info-note",
                        tags$b("Why does scale matter?"), br(),
                        "• ", tags$b("Auto-scaled:"), " highlights fine lap-to-lap variations (tyre wear, fuel burn, and Pit/SC outliers).", br(),
                        "• ", tags$b("Zero-baseline:"), " anchors the axis at 0 s, compressing variance and showing how improper scale bounds can hide real trends."
                    )
                )
            )
        )
      ),

      # ========================================================
      # SECTION 2: RACE PACE KDE & ROBUSTNESS
      # ========================================================
      conditionalPanel(
        "input.show_driver_btn > 0",
        div(id = "tab-kde", class = "pro-tab-section",
            div(class = "pro-split-row",
                div(class = "pro-col-plot",
                    div(class = "f1-card",
                        h4(class = "pro-only pro-card-title", "Kernel Density Estimation of Lap Times"),
                        plotOutput("race_pace_plot", height = "420px")
                    ),
                    div(class = "f1-card-dark",
                        h4(class = "pro-only pro-card-title", "📋 Location & Spread: Mean vs Quartiles"),
                        tableOutput("race_pace_stats")
                    )
                ),
                div(class = "pro-col-controls f1-card-dark",
                    h4(class = "pro-only pro-card-title", "⚙️ KDE & Sample Controls"),
                    radioButtons("race_pace_kernel", "Choose the kernel:",
                                 choiceValues = c("gaussian", "rectangular", "custom"),
                                 choiceNames  = c("Gaussian (Normal)", "Rectangular", "Custom (|u| - Activity 8.1)")),
                    radioButtons("bw_method", "Automatic bandwidth selector:",
                                 choiceValues = c("SJ", "nrd0"),
                                 choiceNames  = c("Sheather-Jones (bw.SJ)", "Silverman Rule-of-Thumb (bw.nrd0)")),
                    sliderInput("bandwidth", "Choose the bandwidth multiplier (adjust): ",
                                min = 0.1, max = 3, value = 1, step = 0.1),
                    checkboxInput("show_individual_kernels", "Show individual kernel contributions", value = FALSE),
                    checkboxInput("include_contamination", "Include Pit/SC/VSC laps", value = FALSE),
                    div(class = "pro-only info-note",
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

      # ========================================================
      # SECTION 3: SIMPSON'S PARADOX (STINTS)
      # ========================================================
      conditionalPanel(
        "input.show_driver_btn > 0",
        div(id = "tab-simpson", class = "pro-tab-section",
            div(class = "pro-split-row",
                div(class = "pro-col-plot f1-card",
                    h4(class = "pro-only pro-card-title", "Overall Normal Laps vs Individual Tyre Stints (Lap > 1)"),
                    plotOutput("simpson_plot", height = "560px")
                ),
                div(class = "pro-col-controls f1-card-dark",
                    h4(class = "pro-only pro-card-title", "⚙️ Regression & Correlations"),
                    checkboxInput("show_simpson_lm", "Show linear regression lines (lm)", value = FALSE),
                    tableOutput("simpson_table"),
                    div(class = "pro-only info-note",
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
