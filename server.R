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

    # Add extra right margin to place legends outside the plot area
    old_par = par(mar = c(5.1, 4.1, 4.1, 9.5))
    on.exit(par(old_par))

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

    # Place both legends outside on the right (stacked vertically)
    par(xpd = TRUE)
    usr   = par("usr")
    x_leg = usr[2] + 0.02 * (usr[2] - usr[1])

    # 1. Compound legend (top right outside)
    leg1 = legend(x = x_leg, y = usr[4],
                  legend = names(COMPOUND_COLORS),
                  pt.bg = COMPOUND_COLORS, pch = 21, pt.cex = 1.3,
                  title = "Compound")

    # 2. Lap Type legend (directly below Compound legend outside)
    leg2_y = leg1$rect$top - leg1$rect$h - 0.05 * (usr[4] - usr[3])
    legend(x = x_leg, y = leg2_y,
           legend = names(LAP_TYPE_COLORS),
           col = LAP_TYPE_COLORS, pch = "|", pt.cex = 1.5,
           title = "Lap Type")
  })
  
  output$race_pace_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    abbr          = driver_result$abbr
    driver_name   = driver_result$name
    team_color    = unname(team_color_by_abbr[abbr])

    # 1. Clean sample (Normal only) vs Contaminated sample (All laps)
    if (isTRUE(input$include_contamination)) {
      selected_laps = lap_data
    } else {
      selected_laps = lap_data[lap_data$LapType == "Normal", ]
    }

    x_vals    = na.omit(selected_laps$LapTime_sec)
    n         = length(x_vals)
    mean_time = mean(x_vals)

    # 2. Automatic bandwidth selector (SJ vs nrd0) multiplied by slider adjust
    bw_method = if (!is.null(input$bw_method)) input$bw_method else "SJ"
    base_bw   = if (bw_method == "SJ") bw.SJ(x_vals) else bw.nrd0(x_vals)
    h         = input$bandwidth * base_bw
    
    if (input$race_pace_kernel == "custom") {
      margin = 4 * h
      grid   = seq(min(x_vals) - margin, max(x_vals) + margin, length.out = 512)
      y_vals = kde_custom(x_vals, grid, h)
      
      d = list(x = grid, y = y_vals)
    } else {
      d = density(x_vals, bw = bw_method, adjust = input$bandwidth, kernel = input$race_pace_kernel)
    }
    
    plot(d$x, d$y,
         type = "l",
         col  = team_color,
         lwd  = 2,                        
         xlab = "Lap Time (sec)",         
         ylab = "Density",                
         main = paste0("Race Pace: ", driver_name,
                       " | Kernel: ", input$race_pace_kernel,
                       " | h = ", round(h, 2), "s (", bw_method, ")")
    )
    # Usa adjustcolor() con trasparenza (0.4) così i singoli kernel sotto si vedono benissimo!
    polygon(d$x, d$y, col = adjustcolor(team_color, alpha.f = 0.4), border = "black", lwd = 2)
    
    # --- TEACHING VIEW: Individual Kernel Contributions ---
    if (input$show_individual_kernels) {
      rug(x_vals, col = "black", lwd = 1.5) # mostra i singoli giri sull'asse X
      
      for (xi in x_vals) {
        if (input$race_pace_kernel == "gaussian") {
          k_y = dnorm(d$x, mean = xi, sd = h) / n
        } else if (input$race_pace_kernel == "rectangular") {
          scale = h / sqrt(1 / 3)
          k_y   = ifelse(abs(d$x - xi) <= scale, 0.5 / scale, 0) / n
        } else if (input$race_pace_kernel == "custom") {
          scale = h / SIGMA_CUSTOM
          k_y   = K_custom((d$x - xi) / scale) / (scale * n)
        }
        lines(d$x, k_y, col = adjustcolor("black", alpha.f = 0.35), lty = 2, lwd = 1)
      }
    }
    
  })

  # ============================================================
  # RACE PACE SUMMARY STATS: Mean & Quartiles (Clean vs Contaminated)
  # ============================================================
  output$race_pace_stats = renderTable({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps

    if (isTRUE(input$include_contamination)) {
      selected_laps = lap_data
      sample_label  = "All Laps (with Pit/SC/VSC)"
    } else {
      selected_laps = lap_data[lap_data$LapType == "Normal", ]
      sample_label  = "Normal Laps Only"
    }

    x_vals = na.omit(selected_laps$LapTime_sec)
    req(length(x_vals) > 0)

    qs = quantile(x_vals, probs = c(0.25, 0.50, 0.75))

    data.frame(
      Sample      = sample_label,
      Laps        = length(x_vals),
      Mean        = round(mean(x_vals), 2),
      Q1_25       = round(unname(qs[1]), 2),
      Median_Q2   = round(unname(qs[2]), 2),
      Q3_75       = round(unname(qs[3]), 2),
      IQR         = round(IQR(x_vals), 2)
    )
  }, striped = TRUE, bordered = TRUE, hover = TRUE)

  # ============================================================
  # SIMPSON'S PARADOX: Overall Normal Laps vs Individual Stints
  # ============================================================
  output$simpson_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    driver_name   = driver_result$name

    # Identify stints: each "PitOut" lap starts a new stint
    lap_data$Stint = cumsum(lap_data$LapType == "PitOut") + 1

    # Filter only Normal laps and exclude Lap 1 (standing start outlier)
    normal_laps = lap_data[lap_data$LapType == "Normal" & lap_data$LapNumber > 1, ]
    req(nrow(normal_laps) > 0)

    all_stints = sort(unique(normal_laps$Stint))
    n_panels   = 1 + length(all_stints) # 1 overall plot + 1 plot per stint

    # Dynamic grid layout (like par(mfrow) in lesson0311.R)
    n_cols  = min(n_panels, 2)
    n_rows  = ceiling(n_panels / n_cols)
    old_par = par(mfrow = c(n_rows, n_cols))
    on.exit(par(old_par))

    # --- 1. GENERAL PLOT (All Normal Laps, identical dots) ---
    plot(normal_laps$LapNumber, normal_laps$LapTime_sec,
         pch  = 19,
         col  = "black",
         cex  = 1.2,
         xlab = "Lap",
         ylab = "Lap Time (sec)",
         main = paste("Overall Normal Laps -", driver_name))

    if (isTRUE(input$show_simpson_lm) && nrow(normal_laps) >= 2) {
      lm_tot = lm(LapTime_sec ~ LapNumber, data = normal_laps)
      abline(lm_tot, col = "red", lwd = 2)
    }

    # --- 2. INDIVIDUAL STINT PLOTS (One plot per stint, colored by tyre compound) ---
    for (s in all_stints) {
      stint_df       = normal_laps[normal_laps$Stint == s, ]
      stint_compound = stint_df$Compound[1]
      stint_colors   = unname(COMPOUND_COLORS[stint_df$Compound])

      plot(stint_df$LapNumber, stint_df$LapTime_sec,
           pch  = 21,
           bg   = stint_colors,
           col  = "black",
           cex  = 1.3,
           xlab = "Lap",
           ylab = "Lap Time (sec)",
           main = paste0("Stint ", s, " (", stint_compound, ")"))

      if (isTRUE(input$show_simpson_lm) && nrow(stint_df) >= 2) {
        lm_stint = lm(LapTime_sec ~ LapNumber, data = stint_df)
        abline(lm_stint, col = "red", lwd = 2)
      }
    }
  })

  # ============================================================
  # SIMPSON'S PARADOX CORRELATION TABLE (like lesson0311.R)
  # ============================================================
  output$simpson_table = renderTable({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps

    lap_data$Stint = cumsum(lap_data$LapType == "PitOut") + 1
    normal_laps    = lap_data[lap_data$LapType == "Normal" & lap_data$LapNumber > 1, ]
    req(nrow(normal_laps) > 0)

    all_stints = sort(unique(normal_laps$Stint))

    # Overall correlation
    cor_tot = if (nrow(normal_laps) >= 2) cor(normal_laps$LapNumber, normal_laps$LapTime_sec, use = "complete.obs") else NA

    groups       = c("Overall (All Normal Laps)")
    compounds    = c(paste(unique(normal_laps$Compound), collapse = " -> "))
    laps_count   = c(nrow(normal_laps))
    correlations = c(cor_tot)

    # Correlation for each stint
    for (s in all_stints) {
      stint_df  = normal_laps[normal_laps$Stint == s, ]
      cor_stint = if (nrow(stint_df) >= 2) cor(stint_df$LapNumber, stint_df$LapTime_sec, use = "complete.obs") else NA

      groups       = c(groups, paste("Stint", s))
      compounds    = c(compounds, stint_df$Compound[1])
      laps_count   = c(laps_count, nrow(stint_df))
      correlations = c(correlations, cor_stint)
    }

    data.frame(
      Group       = groups,
      Compound    = compounds,
      Normal_Laps = laps_count,
      Correlation = round(correlations, 3)
    )
  }, striped = TRUE, bordered = TRUE, hover = TRUE)
}
