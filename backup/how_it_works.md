# 🏎️ 2025 Formula One Championship — Shiny App Technical Documentation

## 1. Application Overview

This **R Shiny** web application enables interactive exploration and statistical analysis of race data from the **2025 Formula 1 World Championship** (collected via the Python `FastF1` library).

Users can:
1. **Select a Grand Prix** from the dropdown menu.
2. **View an instant Grand Prix summary** displaying the event name, round number, circuit location, country, date, and the top 3 podium finishers (with full driver names and teams).
3. **Select a driver** who competed in that specific Grand Prix (displayed with their full name, e.g., `Lando Norris`, `Max Verstappen`, `Charles Leclerc`).
4. **Analyze Lap Times & Race Pace** by clicking the *"Study a driver"* button, which generates two interactive visualizations:
   - **Lap Time Scatter Plot (`lap_time_plot`)**:
     - Shows lap-by-lap times across the entire race.
     - Encodes **Tyre Compound (`Compound`)** via point fill color (`SOFT`, `MEDIUM`, `HARD`, `INTERMEDIATE`, `WET`).
     - Encodes **Lap Condition (`LapType`)** (`Normal`, `PitIn`, `PitOut`, `VSC`, `SC`) via a colored **rug plot** along the X-axis.
     - Allows switching the Y-axis between an **Auto-scaled (min to max)** view and a **Zero-baseline (0 to max)** view.
   - **Race Pace Kernel Density Plot (`race_pace_plot`)**:
     - Estimates the probability density distribution of clean race pace (`Normal` laps only), colored using the driver's official team color.
     - Allows choosing between three **KDE Kernels**: **Gaussian (Normal)**, **Rectangular**, and a **Custom Kernel** ($K_C(u) = |u|$ for $|u| \le 1$, from *Activity 8.1*).
     - Includes an interactive **Bandwidth multiplier slider (`bandwidth`)** applied to the Sheather-Jones (`bw.SJ`) optimal bandwidth to explore under-smoothing and over-smoothing effects.

---

## 2. Architecture & Reactive Flow (How It Works)

The application is structured into the two standard Shiny files: [`ui.R`](file:///C:/Users/filip/Desktop/UniPd/dataVisualizazion/app/ui.R) (user interface layout) and [`server.R`](file:///C:/Users/filip/Desktop/UniPd/dataVisualizazion/app/server.R) (reactive backend logic).

### Data Flow:
1. **Startup (`server.R`)**: The CSV datasets (`f1_laps_2025.csv`, `f1_schedule_2025.csv`, `f1_results_2025.csv`) are loaded once into memory alongside lookup tables that map driver numbers, 3-letter abbreviations, full names, and team hex colors.
2. **Grand Prix Selection (`input$gp_select`)**:
   - Triggers the reactive expressions `laps_selected_gp()`, `results_selected_gp()`, `schedule_selected_gp()`, and `driver_nums_in_gp()`.
   - Automatically updates the text summary (`output$gp_summary`) and populates the driver dropdown (`output$driver_select`) with only the drivers who participated in that race.
3. **Button Click (`input$show_driver_btn`)**:
   - The `eventReactive` expression `selected_driver_data()` captures ("freezes") the selected driver's lap data, abbreviation, and full name at the moment of the click. Changing the driver dropdown afterwards will not alter the plots or their titles until the button is clicked again.
   - The `conditionalPanel` blocks in `ui.R` (`input.show_driver_btn > 0`) reveal the plots and their interactive controls after the first click.
   - Interactive plot controls (`lap_time_plot_scale`, `race_pace_kernel`, `bandwidth`) are read directly inside `renderPlot()`, allowing instant visual updates without needing to re-click *"Study a driver"*.

---

## 3. Variable Naming Guide

All variable names are written in **English** following consistent naming conventions:
- **`UPPER_SNAKE_CASE`** for global constants.
- **`snake_case`** for datasets, local variables, reactive expressions, functions, and UI/Server IDs.

### A. Global Constants & Helper Functions
Defined outside `server()` because they are static across all sessions:

| Name | Type | Description |
|---|---|---|
| `COMPOUND_COLORS` | Named character vector | Maps each tyre compound (`SOFT`, `MEDIUM`, `HARD`, `INTERMEDIATE`, `WET`) to its plot fill color (`red`, `yellow`, `white`, `green`, `blue`). |
| `LAP_TYPE_COLORS` | Named character vector | Maps each lap condition (`Normal`, `PitIn`, `PitOut`, `VSC`, `SC`) to its rug tick color (`forestgreen`, `dodgerblue`, `purple`, `gold`, `darkorange`). |
| `DRIVER_FULL_NAMES` | Named character vector | Maps each 3-letter driver abbreviation (e.g., `"NOR"`, `"VER"`) to their full name (`"Lando Norris"`, `"Max Verstappen"`). |
| `K_custom(u)` | Function | Custom bimodal kernel $K_C(u) = |u|$ for $|u| \le 1$ (and $0$ otherwise) from *Activity 8.1*. |
| `SIGMA_CUSTOM` | Numeric constant | Standard deviation of the unscaled custom kernel ($1/\sqrt{2}$), used to equalize smoothing scale across kernels. |
| `kde_custom(...)` | Function | Computes Kernel Density Estimation over a grid using `K_custom` rescaled by `SIGMA_CUSTOM`. |

---

### B. Static Datasets & Lookup Tables
Loaded once when the server initializes:

| Name | Type | Description |
|---|---|---|
| `laps` | DataFrame (`tibble`) | All lap times and telemetry classifications for the 2025 season (`f1_laps_2025.csv`). |
| `schedule` | DataFrame (`tibble`) | Official 2025 race calendar with locations and dates (`f1_schedule_2025.csv`). |
| `results` | DataFrame (`tibble`) | Final race classifications, points, and team metadata (`f1_results_2025.csv`). |
| `event_names` | Character vector | Unique Grand Prix names extracted from `laps$EventName`. |
| `driver_info` | DataFrame | Deduplicated subset of `results` (one row per driver) containing `DriverNumber`, `Abbreviation`, and `TeamColor`. |
| `driver_num_by_abbr` | Named vector | **Lookup table**: names are 3-letter abbreviations (`"VER"`, `"LEC"`) and values are racing numbers (`1`, `16`). |
| `driver_num_by_name` | Named vector | **Lookup table**: names are full driver names (`"Max Verstappen"`) and values are racing numbers (`1`). Used in `selectInput` so the UI displays full names while passing the driver number to the server. |
| `team_color_by_abbr` | Named vector | **Lookup table**: names are driver abbreviations and values are hex team colors (e.g., `"#FF8000"`). |

---

### C. Reactive Expressions (`reactive` & `eventReactive`)
Dynamic functions recalculated automatically when their dependencies change (called with parentheses `()`):

| Name | Depends On | Return Value |
|---|---|---|
| `laps_selected_gp()` | `input$gp_select` | Subset of `laps` filtered for the currently selected Grand Prix. |
| `results_selected_gp()` | `input$gp_select` | Subset of `results` filtered for the currently selected Grand Prix. |
| `schedule_selected_gp()` | `input$gp_select` | Subset of `schedule` filtered for the currently selected Grand Prix. |
| `driver_nums_in_gp()` | `laps_selected_gp()` | Vector of unique `DriverNumber` values for drivers who participated in the selected GP. |
| `selected_driver_data()` | `input$show_driver_btn` | `eventReactive` updated **only on button click**. Returns `list(laps = ..., abbr = ..., name = ...)` containing the driver's laps, 3-letter abbreviation, and full name. |

---

### D. Input & Output IDs (`ui.R` ↔ `server.R` Communication)

| ID | Type | Description |
|---|---|---|
| `gp_select` | `uiOutput` / `selectInput` | Dropdown menu to select the Grand Prix. |
| `driver_select` | `uiOutput` (UI container) | Dynamic container that renders the driver dropdown menu. |
| `selected_driver_num` | `selectInput` (Input ID) | Racing number of the driver selected by the user. |
| `show_driver_btn` | `actionButton` | *"Study a driver"* button that triggers plot data capture and display. |
| `gp_summary` | `verbatimTextOutput` | Formatted text box showing GP details (Round, Location, Date) and the Podium. |
| `lap_time_plot` | `plotOutput` | Scatter plot of lap times by lap number with compound colors and lap-type rug ticks. |
| `lap_time_plot_scale` | `radioButtons` | Switches the scatter plot Y-axis between `"Default"` (Auto-scaled) and `"Non default"` (Zero-baseline). |
| `race_pace_plot` | `plotOutput` | Kernel Density Estimation (KDE) plot of the driver's normal racing laps. |
| `race_pace_kernel` | `radioButtons` | Selects the KDE kernel shape (`"gaussian"`, `"rectangular"`, `"custom"`). |
| `bandwidth` | `sliderInput` | Bandwidth multiplier (`adjust`) applied to the Sheather-Jones (`bw.SJ`) bandwidth. |

---

### E. Local Variables Inside Rendering Blocks
Temporary variables used inside `renderPrint`, `renderUI`, and `renderPlot`:

- **`gp_info` / `res` / `podium_names`**: schedule row, results table, and top-3 full driver names used to format `output$gp_summary`.
- **`active_driver_nums` / `driver_choices`**: active driver numbers in the selected GP and the filtered named vector passed to `selectInput`.
- **`driver_result`**: list returned by `selected_driver_data()` inside `renderPlot`.
- **`lap_data`**: dataframe of laps for the selected driver (`driver_result$laps`).
- **`normal_laps`**: subset of `lap_data` containing only `"Normal"` racing laps (excluding Pit Stops, VSC, and SC).
- **`abbr` / `driver_name`**: 3-letter abbreviation and full name of the selected driver.
- **`team_color`**: hex color string of the driver's team (stripped of name attributes via `unname()`).
- **`point_colors`**: vector of fill colors for each lap point based on tyre `Compound`.
- **`y_limits`**: numeric vector `c(0, max)` when Zero-baseline is selected, or `NULL` for default auto-scaling.
- **`x_vals` / `h` / `grid` / `y_vals` / `d`**: clean lap-time vector, bandwidth value, evaluation grid, density values, and final `list(x, y)` structure plotted in `output$race_pace_plot`.
