# 🏎️ 2025 Formula 1 Race Pace & Lap Time Explorer

An interactive **R Shiny** web application for visualizing and statistically analyzing lap times, tyre strategies, and race pace distributions across the **2025 Formula 1 World Championship**.

Developed as a project for the **Data Visualization** course at the **University of Padua (UniPd)**.

---

## ✨ Key Features

- **🏁 Grand Prix Overview**:
  - Select any race from the 2025 Formula 1 calendar.
  - Displays circuit location, country, date, round number, and the official **Top 3 Podium** with full driver names and constructors.

- **📈 Lap-by-Lap Scatter Plot & Strategy Analysis**:
  - Visualizes every lap completed by the selected driver across the race distance.
  - **Tyre Compound Encoding**: Points are color-coded according to official Pirelli tyre compounds (`SOFT`, `MEDIUM`, `HARD`, `INTERMEDIATE`, `WET`).
  - **Track & Pit Status Rug Plot**: Colored rug ticks along the horizontal axis highlight special race events (`Normal` green-flag laps, `PitIn`, `PitOut`, `VSC` Virtual Safety Car, and `SC` Safety Car).
  - **Y-Axis Scale Comparison**: Toggle between an **Auto-scaled (Truncated)** Y-axis (to inspect tenth-of-a-second lap variations) and a **Zero-baseline (`[0, max]`)** Y-axis (to evaluate overall magnitude without perceptual distortion).

- **📊 Kernel Density Estimation (KDE) Race Pace Distribution**:
  - Isolates clean racing laps (`Normal` condition) to estimate the driver's true race pace distribution, styled with the driver's official team color.
  - **Interactive Kernel Selection**: Compare standard **Gaussian (Normal)** and **Rectangular** kernels against a counter-intuitive **Custom Bimodal Kernel** ($K_C(u) = |u|$ for $|u| \le 1$) to demonstrate how kernel geometry impacts local density features.
  - **Bandwidth Sensitivity Slider**: Dynamically adjust the Sheather-Jones (`bw.SJ`) smoothing bandwidth multiplier to explore *under-smoothing* (spurious peaks) vs. *over-smoothing* (loss of multi-stint structure).

---

## 📂 Project Structure

```text
app/
├── ui.R                        # Shiny User Interface layout and controls
├── server.R                    # Shiny reactive backend and base R plotting logic
├── downloadAllRaces.py         # Python script (FastF1) to download full season CSVs
├── f1_data_2025/               # Pre-processed 2025 season datasets
│   ├── f1_laps_2025.csv        # Lap-by-lap times, compounds, and track status
│   ├── f1_results_2025.csv     # Race classifications, points, and team colors
│   └── f1_schedule_2025.csv    # 2025 season calendar and circuit metadata
└── backup/                     # Commented reference scripts & technical variable guide
    ├── how_it_works.md         # Detailed architecture & variable naming documentation
    ├── server_commented.R      # Line-by-line commented server code
    └── ui_commented.R          # Line-by-line commented UI code
```

---

## 🚀 Getting Started

### 1. Prerequisites (R Packages)
Make sure you have **R** (and optionally **RStudio**) installed, then install the required packages:

```r
install.packages(c("shiny", "readr", "ggplot2", "vioplot"))
```

### 2. Run the Application
Open R or RStudio, set your working directory to the project folder, and launch the Shiny app:

```r
library(shiny)
runApp("path/to/app")
```
*(Or simply open `server.R` / `ui.R` in RStudio and click the **Run App** button).*

---

## 🐍 Data Collection (Optional)

The repository already includes the pre-extracted CSV files inside `f1_data_2025/`. If you wish to re-generate or update the data using the Python `FastF1` API:

```bash
pip install fastf1 pandas numpy
python downloadAllRaces.py
```

---

## 🛠️ Built With

- **[R Shiny](https://shiny.posit.co/)** — Interactive web framework for R
- **[R Base Graphics](https://stat.ethz.ch/R-manual/R-devel/library/graphics/html/00Index.html)** — Custom scatter plots, rug plots, and KDE polygon rendering
- **[FastF1](https://docs.fastf1.dev/)** — Python library for Formula 1 telemetry and timing data
