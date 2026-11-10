library(readr)    # Fast CSV reading (read_csv)
library(shiny)    # Shiny web application framework
library(ggplot2)  # Grammar of graphics plotting library
library(vioplot)  # Violin plot library

# ============================================================
# GLOBAL CONSTANTS & HELPER FUNCTIONS
# Defined outside server() so they are created once when the app starts
# and shared across all user sessions.
# ============================================================

# Maps each tyre compound to its official F1 display color
COMPOUND_COLORS = c(
  "SOFT"         = "red",
  "MEDIUM"       = "yellow",
  "HARD"         = "white",
  "INTERMEDIATE" = "green",
  "WET"          = "blue"
)

# Maps each lap type to a color used in the X-axis rug plot
LAP_TYPE_COLORS = c(
  "Normal" = "forestgreen",
  "PitIn"  = "dodgerblue",
  "PitOut" = "purple",
  "VSC"    = "gold",
  "SC"     = "darkorange"
)

# Maps each driver's 3-letter abbreviation to their full name (2025 F1 grid)
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

# ============================================================
# CUSTOM KERNEL DENSITY ESTIMATION (from Course Activity 8.1)
# Implements the non-standard v-shaped kernel:
#   K_c(u) = |u|  for |u| <= 1, and 0 otherwise.
# Its theoretical standard deviation is sigma_K = 1 / sqrt(2).
# To make bandwidth h comparable with R's density(), the kernel
# support is rescaled by scale = h / sigma_K.
# ============================================================
K_custom = function(u) {
  ifelse(abs(u) <= 1, abs(u), 0)
}
SIGMA_CUSTOM = 1 / sqrt(2)

kde_custom = function(x, grid, h, kernel = K_custom, kernel_sd = SIGMA_CUSTOM) {
  scale = h / kernel_sd
  # outer(grid, x, "-") builds a matrix of all pairwise differences (grid_j - x_i)
  # rowMeans(...) averages the kernel values across all n observations
  rowMeans(kernel(outer(grid, x, "-") / scale)) / scale
}


# ============================================================
# SERVER
# ============================================================
server = function(input, output, session) {

  # --- 1. Load static CSV datasets once per session ---
  laps     = read_csv("f1_data_2025/f1_laps_2025.csv")     # lap-by-lap timing and tyre data
  schedule = read_csv("f1_data_2025/f1_schedule_2025.csv")  # 2025 race calendar (location, date, round)
  results  = read_csv("f1_data_2025/f1_results_2025.csv")   # final race classification and team colors

  # --- 2. Build lookup vectors ---
  event_names        = unique(laps$EventName)
  # Deduplicate by DriverNumber so each driver appears exactly once in lookup tables
  driver_info        = results[!duplicated(results$DriverNumber), c("DriverNumber", "Abbreviation", "TeamColor")]
  # Named vector: Abbreviation -> DriverNumber (e.g., "VER" = 1)
  driver_num_by_abbr = setNames(driver_info$DriverNumber, driver_info$Abbreviation)
  # Named vector: Full Name -> DriverNumber (used to display full names in the dropdown)
  driver_num_by_name = setNames(driver_info$DriverNumber, DRIVER_FULL_NAMES[driver_info$Abbreviation])
  # Named vector: Abbreviation -> Hex TeamColor with leading '#' (e.g., "VER" = "#3671C6")
  team_color_by_abbr = setNames(paste0("#", driver_info$TeamColor), driver_info$Abbreviation)


  # ============================================================
  # DYNAMIC UI SELECTORS (Sidebar)
  # ============================================================

  # Renders the Grand Prix dropdown populated from the CSV data
  output$gp_select = renderUI({
    selectInput("gp_select", "Grand Prix: ",
                choices  = event_names,
                selected = event_names[1]
                )
  })

  # Reactive subsets filtered by the currently selected Grand Prix
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

  # Driver numbers that actually took part in the selected GP
  driver_nums_in_gp = reactive({
    req(input$gp_select) # wait for input reading
    unique(laps_selected_gp()$DriverNumber)
  })


  # ============================================================
  # GRAND PRIX SUMMARY CARD
  # Displays GP metadata (name, round, location, date) and the Top 3 podium.
  # ============================================================
  output$gp_summary = renderPrint({
    req(input$gp_select) # wait for input reading
    gp_info      = schedule_selected_gp()
    res          = results_selected_gp()
    podium_names = DRIVER_FULL_NAMES[res$Abbreviation[1:3]]

    cat("🏁 ", gp_info$EventName[1], " (Round ", gp_info$RoundNumber[1], ")\n", sep = "")
    cat("📍 Location: ", gp_info$Location[1], ", ", gp_info$Country[1], "\n", sep = "")
    cat("📅 Date:     ", as.character(gp_info$EventDate[1]), "\n\n", sep = "")
    cat("🏆 Podium:\n")
    cat("   🥇 1st: ", podium_names[1], " (", res$TeamName[1], ")\n", sep = "")
    cat("   🥈 2nd: ", podium_names[2], " (", res$TeamName[2], ")\n", sep = "")
    cat("   🥉 3rd: ", podium_names[3], " (", res$TeamName[3], ")\n", sep = "")
  })

  # Renders the Driver dropdown showing full driver names sorted alphabetically,
  # while passing their DriverNumber as the underlying input value.
  output$driver_select = renderUI({
    req(input$gp_select) # wait for input reading
    active_driver_nums = driver_nums_in_gp()
    driver_choices     = driver_num_by_name[driver_num_by_name %in% active_driver_nums]
    selectInput("selected_driver_num", "Select driver: ",
                choices  = sort(driver_choices),
                selected = driver_nums_in_gp()[1]
                )
  })

  # Captures a snapshot of the selected driver's laps only when "Study a driver" is clicked
  selected_driver_data = eventReactive(input$show_driver_btn, {
    lap_data    = laps_selected_gp()[laps_selected_gp()$DriverNumber == input$selected_driver_num, ]
    driver_abbr = names(driver_num_by_abbr)[driver_num_by_abbr == input$selected_driver_num][1]
    driver_name = unname(DRIVER_FULL_NAMES[driver_abbr])
    list(laps = lap_data, abbr = driver_abbr, name = driver_name)
  })


  # ============================================================
  # PLOT 1: LAP TIME SCATTER PLOT + RUG + SCALE TOGGLE
  # - Points colored by Tyre Compound (pch = 21 with black border)
  # - Colored rug ticks on X-axis indicating LapType (Normal, PitIn, PitOut, VSC, SC)
  # - Y-axis toggle between Auto-scaled [min, max] and Zero-baseline [0, max]
  #   to demonstrate the visual distortion / Lie Factor of y-axis truncation
  # - Both legends placed outside the plot area on the right
  # ============================================================
  output$lap_time_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    abbr          = driver_result$abbr
    driver_name   = driver_result$name
    team_color    = unname(team_color_by_abbr[abbr])
    point_colors  = unname(COMPOUND_COLORS[lap_data$Compound])
    
    # Choose Y-axis limits based on radio button selection
    if (input$lap_time_plot_scale == "Non default") {
      y_limits = c(0, max(lap_data$LapTime_sec, na.rm = TRUE))
    } else {
      y_limits = NULL   # NULL tells R to use its default [min, max] scale
    }

    # Increase right margin (9.5 lines) to make room for external legends,
    # and restore default graphical parameters on exit
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

    # Draw colored rug ticks along the X-axis for each lap type
    for (lt in names(LAP_TYPE_COLORS)) {
      laps_of_type = lap_data$LapNumber[lap_data$LapType == lt]
      if (length(laps_of_type) > 0) {
        rug(laps_of_type, col = LAP_TYPE_COLORS[lt], lwd = 2.5, ticksize = 0.03)
      }
    }

    # Allow drawing outside the plot box (in the right margin)
    par(xpd = TRUE)
    usr   = par("usr")                         # c(x_min, x_max, y_min, y_max)
    x_leg = usr[2] + 0.02 * (usr[2] - usr[1])  # X position slightly to the right of the plot border

    # 1. Compound legend (top-right outside)
    leg1 = legend(x = x_leg, y = usr[4],
                  legend = names(COMPOUND_COLORS),
                  pt.bg = COMPOUND_COLORS, pch = 21, pt.cex = 1.3,
                  title = "Compound")

    # 2. Lap Type legend (stacked directly below the Compound legend using leg1$rect dimensions)
    leg2_y = leg1$rect$top - leg1$rect$h - 0.05 * (usr[4] - usr[3])
    legend(x = x_leg, y = leg2_y,
           legend = names(LAP_TYPE_COLORS),
           col = LAP_TYPE_COLORS, pch = "|", pt.cex = 1.5,
           title = "Lap Type")
  })


  # ============================================================
  # PLOT 2: RACE PACE KERNEL DENSITY ESTIMATION (KDE)
  # Implements the requirements from Activity 8.1 and Project Guidelines:
  # 1. Clean sample (Normal laps) vs Contaminated sample (including Pit/SC/VSC outliers)
  # 2. Automatic bandwidth selector: Sheather-Jones (bw.SJ) vs Silverman's Rule (bw.nrd0)
  # 3. Interactive bandwidth multiplier (adjust slider)
  # 4. Kernel choice: Gaussian, Rectangular, or Custom v-shaped kernel |u|
  # 5. Teaching View checkbox: overlays the individual kernel functions centered at each lap x_i
  # ============================================================
  output$race_pace_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    abbr          = driver_result$abbr
    driver_name   = driver_result$name
    team_color    = unname(team_color_by_abbr[abbr])

    # 1. Filter clean sample (Normal laps only) or contaminated sample (All laps)
    if (isTRUE(input$include_contamination)) {
      selected_laps = lap_data
    } else {
      selected_laps = lap_data[lap_data$LapType == "Normal", ]
    }

    x_vals    = na.omit(selected_laps$LapTime_sec)
    n         = length(x_vals)
    mean_time = mean(x_vals)

    # 2. Compute effective bandwidth h = adjust * base_bw (using SJ or nrd0)
    bw_method = if (!is.null(input$bw_method)) input$bw_method else "SJ"
    base_bw   = if (bw_method == "SJ") bw.SJ(x_vals) else bw.nrd0(x_vals)
    h         = input$bandwidth * base_bw
    
    # 3. Evaluate KDE either via custom kernel function or R's built-in density()
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
    # Fill density curve with semi-transparent team color (alpha = 0.4) so individual kernels remain visible
    polygon(d$x, d$y, col = adjustcolor(team_color, alpha.f = 0.4), border = "black", lwd = 2)
    
    # 4. Teaching View: draw individual kernel contributions K_h(x - x_i) / n
    if (input$show_individual_kernels) {
      rug(x_vals, col = "black", lwd = 1.5) # mark exact observations on X-axis
      
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
  # TABLE 1: RACE PACE SUMMARY STATISTICS (Clean vs Contaminated)
  # Shows how the Mean is heavily pulled upward by Pit/SC/VSC outliers,
  # whereas the Quartiles (Q1, Median Q2, Q3) and IQR remain robust.
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
  # PLOT 3: SIMPSON'S PARADOX (Overall Normal Laps vs Individual Stints)
  # Inspired by lesson0311.R:
  # - Across the whole race (Overall plot), lap times often trend downward
  #   because fuel load decreases (~100 kg burned from start to finish) and
  #   fresh tyres are fitted at pit stops.
  # - Within a single tyre stint (conditioning on Stint), tyre wear can cause
  #   lap times to trend upward (or change slope/sign compared to the overall trend).
  # - Lap 1 is excluded (LapNumber > 1) because the standing start and turn-1 traffic
  #   make it a high-leverage outlier that would artificially pull Stint 1's slope down.
  # ============================================================
  output$simpson_plot = renderPlot({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps
    driver_name   = driver_result$name

    # Identify stints dynamically: each "PitOut" lap increments the stint counter
    lap_data$Stint = cumsum(lap_data$LapType == "PitOut") + 1

    # Keep only Normal racing laps and exclude Lap 1 (standing start)
    normal_laps = lap_data[lap_data$LapType == "Normal" & lap_data$LapNumber > 1, ]
    req(nrow(normal_laps) > 0)

    all_stints = sort(unique(normal_laps$Stint))
    n_panels   = 1 + length(all_stints) # 1 overall plot + 1 subplot per stint

    # Dynamic multi-panel grid layout (2 columns, as many rows as needed)
    n_cols  = min(n_panels, 2)
    n_rows  = ceiling(n_panels / n_cols)
    old_par = par(mfrow = c(n_rows, n_cols))
    on.exit(par(old_par))

    # --- Panel 1: Overall Normal Laps (all points identical black circles) ---
    plot(normal_laps$LapNumber, normal_laps$LapTime_sec,
         pch  = 19,
         col  = "black",
         cex  = 1.2,
         xlab = "Lap",
         ylab = "Lap Time (sec)",
         main = paste("Overall Normal Laps -", driver_name))

    # Optional linear regression line for the overall data
    if (isTRUE(input$show_simpson_lm) && nrow(normal_laps) >= 2) {
      lm_tot = lm(LapTime_sec ~ LapNumber, data = normal_laps)
      abline(lm_tot, col = "red", lwd = 2)
    }

    # --- Subsequent Panels: One subplot per Stint, colored by Tyre Compound ---
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

      # Optional linear regression line for the individual stint
      if (isTRUE(input$show_simpson_lm) && nrow(stint_df) >= 2) {
        lm_stint = lm(LapTime_sec ~ LapNumber, data = stint_df)
        abline(lm_stint, col = "red", lwd = 2)
      }
    }
  })


  # ============================================================
  # TABLE 2: SIMPSON'S PARADOX CORRELATION TABLE
  # Mirrors the correlation summary table from lesson0311.R:
  # Compares Pearson's r = cor(LapNumber, LapTime_sec) overall vs within each stint.
  # ============================================================
  output$simpson_table = renderTable({
    driver_result = selected_driver_data()
    lap_data      = driver_result$laps

    lap_data$Stint = cumsum(lap_data$LapType == "PitOut") + 1
    normal_laps    = lap_data[lap_data$LapType == "Normal" & lap_data$LapNumber > 1, ]
    req(nrow(normal_laps) > 0)

    all_stints = sort(unique(normal_laps$Stint))

    # Overall correlation across all normal laps (excluding Lap 1)
    cor_tot = if (nrow(normal_laps) >= 2) cor(normal_laps$LapNumber, normal_laps$LapTime_sec, use = "complete.obs") else NA

    groups       = c("Overall (All Normal Laps)")
    compounds    = c(paste(unique(normal_laps$Compound), collapse = " -> "))
    laps_count   = c(nrow(normal_laps))
    correlations = c(cor_tot)

    # Within-stint correlation for each stint
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
