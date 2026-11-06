library(shiny)

# ============================================================
# UI
# Defines the visual layout of the app.
# fluidPage() creates a responsive full-width page.
# ============================================================
ui = fluidPage(
  titlePanel("🏎️ 2025 Formula One Championship"),

  # sidebarLayout() splits the page into two areas:
  #   sidebarPanel — narrow left column for controls
  #   mainPanel    — wide right column for outputs
  sidebarLayout(

    sidebarPanel(
      # GP dropdown — populated dynamically by server (renderUI)
      uiOutput("gp_select"),

      # Driver dropdown — populated dynamically based on selected GP
      uiOutput("driver_select"),

      # Button that triggers the plot rendering.
      # class = "btn-primary btn-block" applies Bootstrap styling:
      #   btn-primary → blue color
      #   btn-block   → full width inside the sidebar
      actionButton("show_driver_btn", "Study a driver",
                   class = "btn-primary btn-block")
    ),

    mainPanel(
      # Text output showing a statistical summary of the selected GP
      verbatimTextOutput("gp_summary"),

      # conditionalPanel hides the plot until the button has been clicked at least once.
      # The condition is evaluated as JavaScript: input.show_driver_btn > 0
      # (Shiny automatically exposes input values to JS with dot notation)
      conditionalPanel("input.show_driver_btn > 0", plotOutput("lap_time_plot"))
    )
  )
)
