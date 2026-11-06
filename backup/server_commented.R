setwd("C:/Users/filip/Desktop/UniPd/dataVisualizazion/app")
library(readr)    # for read_csv
library(shiny)    # Shiny web app framework
library(ggplot2)  # plotting library (available for future use)

# ============================================================
# GLOBAL CONSTANTS
# Named vectors used to map values to visual properties.
# Defined outside server() so they are shared across all user sessions.
# ============================================================

# Maps each tyre compound to a display color
COMPOUND_COLORS = c(
  "SOFT"         = "red",
  "MEDIUM"       = "yellow",
  "HARD"         = "white",
  "INTERMEDIATE" = "green",
  "WET"          = "blue"
)

# Maps each lap type to a plot point shape (pch value in base R graphics)
# pch = 21-25 are filled shapes that support both border color (col) and fill color (bg)
LAP_TYPE_SHAPES = c(
  "Normal"  = 21,   # circle
  "PitIn"   = 24,   # up triangle
  "PitOut"  = 25,   # down triangle
  "VSC"     = 22,   # square
  "SC"      = 23    # rhombus
)

# ============================================================
# SERVER
# The server function receives input from the UI, processes data
# reactively, and sends output back to the UI.
# ============================================================
server = function(input, output, session) {

  # --- Load static datasets once at startup ---
  laps     = read_csv("f1_data_2025/f1_laps_2025.csv")     # all lap data for the season
  schedule = read_csv("f1_data_2025/f1_schedule_2025.csv")  # race calendar
  results  = read_csv("f1_data_2025/f1_results_2025.csv")   # race classification results

  # --- Build lookup tables from the results dataset ---

  # List of unique Grand Prix names, used to populate the GP dropdown
  event_names = unique(laps$EventName)

  # Keep only one row per driver (first occurrence) to avoid duplicates
  # across multiple GPs (e.g. same driver with slightly different TeamColor entries)
  driver_info = results[!duplicated(results$DriverNumber), c("DriverNumber", "Abbreviation", "TeamColor")]

  # Named vector: given an abbreviation (e.g. "VER"), returns the driver number (e.g. 1)
  # Structure: c("VER" = 1, "NOR" = 4, "LEC" = 16, ...)
  driver_num_by_abbr = setNames(driver_info$DriverNumber, driver_info$Abbreviation)

  # Named vector: given an abbreviation, returns the team hex color (e.g. "#3671C6")
  # paste0("#", ...) adds the # prefix missing from the raw CSV value
  team_color_by_abbr = setNames(paste0("#", driver_info$TeamColor), driver_info$Abbreviation)


  # ============================================================
  # GP SELECTOR
  # Renders a dropdown with all Grand Prix names.
  # Using renderUI (instead of a static selectInput in ui.R) allows
  # the choices to be populated dynamically from the loaded data.
  # ============================================================
  output$gp_select = renderUI({
    selectInput("gp_select", "Grand Prix: ",
                choices  = event_names,
                selected = event_names[1]  # pre-select the first GP
                )
  })


  # ============================================================
  # REACTIVE: laps_selected_gp
  # Filters the full laps dataset to only the rows matching
  # the currently selected Grand Prix.
  # Re-runs automatically whenever input$gp_select changes.
  # req() stops execution silently if the input is not yet available
  # (e.g. during initial UI rendering).
  # ============================================================
  laps_selected_gp = reactive({
    req(input$gp_select) # wait for input reading
    laps[laps$EventName == input$gp_select, ]
  })

  # Filters results to the selected GP (used for classification data)
  results_selected_gp = reactive({
    req(input$gp_select) # wait for input reading
    results[results$EventName == input$gp_select, ]
  })

  # Extracts the unique driver numbers that participated in the selected GP
  driver_nums_in_gp = reactive({
    req(input$gp_select) # wait for input reading
    unique(laps_selected_gp()$DriverNumber)
  })


  # Prints a statistical summary of the selected GP laps (debug/exploration output)
  output$gp_summary = renderPrint({
    req(input$gp_select) # wait for input reading
    lap_data = laps_selected_gp()
    summary(lap_data)
    results_selected_gp()$Abbreviation[1:3]  # show top 3 finishers
  })


  # ============================================================
  # DRIVER SELECTOR
  # Renders a dropdown populated only with drivers who raced
  # in the currently selected GP.
  #
  # How it works:
  #   1. Get the driver numbers active in this GP
  #   2. Filter driver_num_by_abbr to only those numbers
  #      (this gives a named vector: abbreviation -> number)
  #   3. Pass it to selectInput as choices:
  #      Shiny displays the NAME (abbreviation) but the VALUE
  #      sent to input$selected_driver_num is the NUMBER
  # ============================================================
  output$driver_select = renderUI({
    req(input$gp_select) # wait for input reading
    active_driver_nums = driver_nums_in_gp()

    # Keep only entries whose value (driver number) is in active_driver_nums
    driver_choices = driver_num_by_abbr[driver_num_by_abbr %in% active_driver_nums]

    selectInput("selected_driver_num", "Select driver: ",
                choices  = sort(driver_choices),  # sort alphabetically by abbreviation
                selected = driver_nums_in_gp()[1]
                )
  })


  # ============================================================
  # EVENT REACTIVE: selected_driver_data
  # Unlike reactive(), eventReactive() only re-runs when a specific
  # event fires — here, when the user clicks "show_driver_btn".
  # This "freezes" the plot data at the moment of the click,
  # so changing the dropdown afterwards does NOT update the plot
  # until the button is clicked again.
  #
  # Returns a list with:
  #   $laps — filtered lap data for the selected driver
  #   $abbr — the driver's 3-letter abbreviation (single value)
  # ============================================================
  selected_driver_data = eventReactive(input$show_driver_btn, {
    # Filter laps to only the selected driver
    lap_data = laps_selected_gp()[laps_selected_gp()$DriverNumber == input$selected_driver_num, ]

    # Look up the abbreviation from the driver number.
    # [1] ensures a single value is returned even if multiple matches exist
    # (can happen if the same driver number appears more than once in the lookup table)
    driver_abbr = names(driver_num_by_abbr)[driver_num_by_abbr == input$selected_driver_num][1]

    list(laps = lap_data, abbr = driver_abbr)
  })


  # ============================================================
  # LAP TIME SCATTER PLOT
  # X axis: lap number
  # Y axis: lap time in seconds
  # Point color (bg): tyre compound
  # Point shape (pch): lap type (Normal, PitIn, PitOut, VSC, SC)
  # ============================================================
  output$lap_time_plot = renderPlot({
    driver_result = selected_driver_data()  # retrieve the frozen snapshot
    lap_data      = driver_result$laps
    abbr          = driver_result$abbr

    # Look up visual properties for each lap row.
    # unname() strips the vector's name attribute, which is required by
    # graphical parameters like col.main that expect a plain unnamed value.
    team_color   = unname(team_color_by_abbr[abbr])               # driver's team color (hex)
    point_colors = unname(COMPOUND_COLORS[lap_data$Compound])      # one color per lap row
    point_shapes = unname(LAP_TYPE_SHAPES[lap_data$LapType])       # one shape per lap row

    plot(lap_data$LapNumber, lap_data$LapTime_sec,
         bg   = point_colors,   # fill color of each point
         col  = "black",        # border color of each point
         pch  = point_shapes,   # shape of each point
         cex  = 1.3,            # point size scaling factor
         xlab = "Lap",
         ylab = "Lap Time (sec)",
         main = paste("Driver:", abbr)
         )

    # Legend for tyre compounds (top right)
    legend("topright", legend = names(COMPOUND_COLORS),
           pt.bg = COMPOUND_COLORS, pch = 21, pt.cex = 1.3)

    # Legend for lap types (top left)
    legend("topleft", legend = names(LAP_TYPE_SHAPES),
           pch = LAP_TYPE_SHAPES, pt.cex = 1.3)
  })
}
