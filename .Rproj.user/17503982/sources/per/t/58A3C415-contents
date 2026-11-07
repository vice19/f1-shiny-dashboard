library(readr)
library(shiny)
library(ggplot2)
library(vioplot)

COMPOUND_COLORS = c(
  "SOFT"         = "red",
  "MEDIUM"       = "yellow",
  "HARD"         = "white",
  "INTERMEDIATE" = "green",
  "WET"          = "blue"
)
# LAP_TYPE_SHAPES = c(
#   "Normal"  = 21,   # circle
#   "PitIn"   = 24,   # up triangle
#   "PitOut"  = 25,   # down triangle
#   "VSC"     = 22,   # square
#   "SC"      = 23    # rhombus
# )
LAP_TYPE_COLORS = c(
  "Normal" = "forestgreen",
  "PitIn"  = "dodgerblue",
  "PitOut" = "purple",
  "VSC"    = "gold",
  "SC"     = "darkorange"
)

DRIVER_FULL_NAMES = c(
  "NOR" = "Lando Norris",
  "VER" = "Max Verstappen",
  "RUS" = "George Russell",
  "ANT" = "Kimi Antonelli",
  "ALB" = "Alexander Albon",
  "STR" = "Lance Stroll",
  "HUL" = "Nico Hülkenberg",
  "LEC" = "Charles Leclerc",
  "PIA" = "Oscar Piastri",
  "HAM" = "Lewis Hamilton",
  "GAS" = "Pierre Gasly",
  "TSU" = "Yuki Tsunoda",
  "OCO" = "Esteban Ocon",
  "BEA" = "Oliver Bearman",
  "LAW" = "Liam Lawson",
  "BOR" = "Gabriel Bortoleto",
  "ALO" = "Fernando Alonso",
  "SAI" = "Carlos Sainz",
  "DOO" = "Jack Doohan",
  "HAD" = "Isack Hadjar",
  "COL" = "Franco Colapinto"
)

# Custom kernel from Activity 8.1: K_c(u) = |u| for |u| <= 1
K_custom = function(u) {
  ifelse(abs(u) <= 1, abs(u), 0)
}
SIGMA_CUSTOM = 1 / sqrt(2)

kde_custom = function(x, grid, h, kernel = K_custom, kernel_sd = SIGMA_CUSTOM) {
  scale = h / kernel_sd
  rowMeans(kernel(outer(grid, x, "-") / scale)) / scale
}

server = function(input, output, session) {
  laps     = read_csv("f1_data_2025/f1_laps_2025.csv")
  schedule = read_csv("f1_data_2025/f1_schedule_2025.csv")
  results  = read_csv("f1_data_2025/f1_results_2025.csv")

  event_names        = unique(laps$EventName)
  driver_info        = results[!duplicated(results$DriverNumber), c("DriverNumber", "Abbreviation", "TeamColor")]
  driver_num_by_abbr = setNames(driver_info$DriverNumber, driver_info$Abbreviation)
  driver_num_by_name = setNames(driver_info$DriverNumber, DRIVER_FULL_NAMES[driver_info$Abbreviation])
  team_color_by_abbr = setNames(paste0("#", driver_info$TeamColor), driver_info$Abbreviation)

  output$gp_select = renderUI({
    selectInput("gp_select", "Grand Prix: ",
                choices  = event_names,
                selected = event_names[1]
                )
  })

  # output$preview = renderPrint({
  #   input$gp_select
  # })

  laps_selected_gp = reactive({
    req(input$gp_select) # wait for input reading
    laps[laps$EventName == input$gp_select, ]
  })
  results_selected_gp = reactive({
    req(input$gp_select) # wait for input reading
    results[results$EventName == input$gp_select, ]
  })
  schedule_selected_gp = reactive({
    req(input$gp_select) # wait for input reading
    schedule[schedule$EventName == input$gp_select, ]
  })

  driver_nums_in_gp = reactive({
    req(input$gp_select) # wait for input reading
    unique(laps_selected_gp()$DriverNumber)
  })

  output$gp_summary = renderPrint({
    req(input$gp_select) # wait for input reading
    gp_info = schedule_selected_gp()
    res     = results_selected_gp()
    podium_names = DRIVER_FULL_NAMES[res$Abbreviation[1:3]]

    cat("🏁 ", gp_info$EventName[1], " (Round ", gp_info$RoundNumber[1], ")\n", sep = "")
    cat("📍 Location: ", gp_info$Location[1], ", ", gp_info$Country[1], "\n", sep = "")
    cat("📅 Date:     ", as.character(gp_info$EventDate[1]), "\n\n", sep = "")
    cat("🏆 Podium:\n")
    cat("   🥇 1st: ", podium_names[1], " (", res$TeamName[1], ")\n", sep = "")
    cat("   🥈 2nd: ", podium_names[2], " (", res$TeamName[2], ")\n", sep = "")
    cat("   🥉 3rd: ", podium_names[3], " (", res$TeamName[3], ")\n", sep = "")
  })

  output$driver_select = renderUI({
    req(input$gp_select) # wait for input reading
    active_driver_nums = driver_nums_in_gp()
    driver_choices     = driver_num_by_name[driver_num_by_name %in% active_driver_nums]
    selectInput("selected_driver_num", "Select driver: ",
                choices  = sort(driver_choices),
                selected = driver_nums_in_gp()[1]
                )
  })

  selected_driver_data = eventReactive(input$show_driver_btn, {
    lap_data    = laps_selected_gp()[laps_selected_gp()$DriverNumber == input$selected_driver_num, ]
    driver_abbr = names(driver_num_by_abbr)[driver_num_by_abbr == input$selected_driver_num][1]
    driver_name = unname(DRIVER_FULL_NAMES[driver_abbr])
    list(laps = lap_data, abbr = driver_abbr, name = driver_name)
  })

  output$lap_time_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    abbr          = driver_result$abbr
    driver_name   = driver_result$name
    team_color    = unname(team_color_by_abbr[abbr])
    point_colors  = unname(COMPOUND_COLORS[lap_data$Compound])
    
    #if for choose the scale
    if (input$lap_time_plot_scale == "Non default") {
      y_limits = c(0, max(lap_data$LapTime_sec, na.rm = TRUE))
    } else {
      y_limits = NULL   # NULL tells R to use its default [min, max] scale
    }

    plot(lap_data$LapNumber, lap_data$LapTime_sec,
         bg       = point_colors,
         col      = "black",
         pch      = 21,
         cex      = 1.3,
         xlab     = "Lap",
         ylab     = "Lap Time (sec)",
         main     = paste("Driver:", driver_name),
         ylim     = y_limits
         )
    # Draw colored rug ticks for each lap type
    for (lt in names(LAP_TYPE_COLORS)) {
      laps_of_type = lap_data$LapNumber[lap_data$LapType == lt]
      if (length(laps_of_type) > 0) {
        rug(laps_of_type, col = LAP_TYPE_COLORS[lt], lwd = 2.5, ticksize = 0.03)
      }
    }

    # compound legend
    legend("topright", legend = names(COMPOUND_COLORS),
           pt.bg = COMPOUND_COLORS, pch = 21, pt.cex = 1.3)
    # lap type legend (rug colors)
    legend("topleft", legend = names(LAP_TYPE_COLORS),
           col = LAP_TYPE_COLORS, pch = "|", pt.cex = 1.5, title = "Lap Type")
  })
  
  output$race_pace_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    normal_laps   = lap_data[lap_data$LapType == "Normal",]
    abbr          = driver_result$abbr
    driver_name   = driver_result$name
    team_color    = unname(team_color_by_abbr[abbr])
    mean_time     = mean(normal_laps$LapTime_sec)
    
    x_vals = na.omit(normal_laps$LapTime_sec)
    
    if (input$race_pace_kernel == "custom") {
      # Calcola bandwidth e griglia come in Activity 8.1
      h = input$bandwidth * bw.SJ(x_vals)
      margin = 4 * h
      grid   = seq(min(x_vals) - margin, max(x_vals) + margin, length.out = 512)
      y_vals = kde_custom(x_vals, grid, h)
      
      d = list(x = grid, y = y_vals) # stessa struttura di density()!
    } else {
      # "gaussian" o "rectangular" sono già inclusi in density()
      d = density(x_vals, bw = "SJ", adjust = input$bandwidth, kernel = input$race_pace_kernel)
    }
    
    plot(d$x, d$y,
         type = "l",
         col  = team_color,
         lwd  = 2,                        
         xlab = "Lap Time (sec)",         
         ylab = "Density",                
         main = paste("Race Pace:", driver_name, "- Kernel:", input$race_pace_kernel)
    )
    polygon(d$x, d$y, col = team_color, border = "black")
    
  })
}
