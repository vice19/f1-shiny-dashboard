# 🏎️ 2025 Formula 1 Telemetry & Statistical Visualization Explorer

An interactive **R Shiny** web application for exploring lap-by-lap telemetry, tyre strategies, non-parametric density estimation, outlier robustness, and **Simpson's Paradox** across the **2025 Formula 1 World Championship**.

Developed for the **Data Visualization** course at the **University of Padua (UniPd)**.

---

## ✨ Key Features & Statistical Concepts

### 1. 🏁 Grand Prix Overview & Classification
- Dynamically select any Grand Prix from the **2025 Formula 1 calendar** and filter by participating drivers.
- Displays event metadata (round number, circuit location, country, date) alongside the official **Top 3 Podium** with full driver names and constructors.

### 2. 📈 Lap-by-Lap Telemetry & Y-Axis Scale Distortion
- **Tyre Compound Encoding**: Every lap is color-coded by its official Pirelli compound (`SOFT`, `MEDIUM`, `HARD`, `INTERMEDIATE`, `WET`).
- **Track & Pit Status Rug Plot**: Colored rug ticks along the horizontal axis mark special race events (`Normal` green-flag racing laps, `PitIn`, `PitOut`, `VSC` Virtual Safety Car, and `SC` Safety Car), with stacked external legends that never occlude data points.
- **Perceptual Scale Comparison**: Toggle between:
  - **Auto-scaled (`[min, max]`)**: zooms into the active data range to reveal tenth-of-a-second pace variations, fuel burn, and pit/safety car outliers.
  - **Zero-baseline (`[0, max]`)**: anchors the vertical axis at $0\text{ s}$, illustrating how improper axis bounds compress variance and obscure meaningful trends.

### 3. 📊 Race Pace Kernel Density Estimation (KDE) & Outlier Robustness
- Estimates the probability density function of a driver's lap times, shaded in the driver's official constructor color:
  $$\hat{f}_h(x) = \frac{1}{n} \sum_{i=1}^{n} \frac{1}{h} K\left(\frac{x - x_i}{h}\right)$$
- **Kernel Geometry Comparison**:
  - **Gaussian (Normal)** and **Rectangular (Uniform)** standard kernels.
  - **Custom V-Shaped Kernel** ($K_C(u) = |u|$ for $|u| \le 1$, with $\sigma_K = 1/\sqrt{2}$), demonstrating how a bimodal kernel splits each observation into two side peaks at small bandwidths while converging to the true macroscopic density at larger bandwidths.
- **Automatic Bandwidth Selectors & Multiplier**:
  - Switch between **Sheather-Jones (`bw.SJ`)** and **Silverman's Rule-of-Thumb (`bw.nrd0`)**, and scale the resulting bandwidth $h$ interactively via the `adjust` slider ($0.1\times$ to $3.0\times$).
- **Teaching View (Individual Kernel Contributions)**:
  - Overlays the $n$ individual scaled kernel functions centered at each observed lap time $x_i$ (plus an X-axis rug plot) to show how they sum to form the global KDE curve.
- **Outlier Contamination & Robustness Table**:
  - Toggle **"Include Pit/SC/VSC laps"** to inject extreme right-tail outliers ($110\text{--}150\text{ s}$) into the clean racing sample.
  - A live summary table compares the **Sample Mean** (heavily distorted by pit stops and Safety Cars, which also inflates `bw.nrd0`) against the **Quartiles (`Q1`, `Median Q2`, `Q3`) and `IQR`**, highlighting the statistical robustness of order statistics.

### 4. 🔄 Simpson's Paradox in Tyre Stints
- Investigates the relationship between `LapNumber` and `LapTime_sec` across clean racing laps (excluding Lap 1 to remove standing-start distortion):
  - **Overall Trend (Aggregated Data)**: Across the full race distance, cars burn $\sim 100\text{ kg}$ of fuel (becoming $\sim 0.03\text{--}0.04\text{ s/lap}$ faster) and pit for fresh tyres, often producing a **negative overall correlation** ($r < 0$, lap times decreasing with lap number).
  - **Within-Stint Trend (Stratified by Tyre Stint)**: Conditioning on the confounding variable **`Stint`** (each continuous run between pit stops, colored by compound) reveals progressive tyre degradation, often reversing the sign to a **positive correlation** ($r > 0$, lap times increasing within each stint).
- Includes an interactive checkbox to overlay **Ordinary Least Squares (`lm`) regression lines** and a **Correlation Summary Table** reporting Pearson's $r$ overall and for each individual stint.

---

## 📂 Repository Structure

```text
app/
├── ui.R                          # Classic single-page Shiny UI layout
├── server.R                      # Core Shiny server logic, custom KDE, and plotting engine
├── pro_ui/                       # Modern F1 Telemetry Dashboard UI (Tabbed interface)
│   ├── ui.R                      # Styled multi-tab dashboard with side-by-side controls
│   └── server.R                  # Lightweight wrapper sourcing the main ../server.R
├── downloadAllRaces.py           # Python script (FastF1) to download & build season CSVs
├── f1_data_2025/                 # Pre-processed 2025 Formula 1 World Championship dataset
│   ├── f1_laps_2025.csv          # Lap-by-lap timing, tyre compounds, and track status
│   ├── f1_results_2025.csv       # Race classifications, points, and hex team colors
│   └── f1_schedule_2025.csv      # 2025 race calendar, circuit locations, and dates
└── backup/                       # Annotated reference scripts & technical documentation
    ├── how_it_works.md           # Architecture, data flow, and variable naming guide
    ├── server_commented.R        # Commented server backup (v1 milestone)
    ├── ui_commented.R            # Commented UI backup (v1 milestone)
    ├── server_commented_v2.R     # Fully commented server backup (current full version)
    └── ui_commented_v2.R         # Fully commented UI backup (current full version)
```

---

## 🚀 Getting Started

### 1. Prerequisites
Install **R** (and optionally **RStudio**), then install the required R packages:

```r
install.packages(c("shiny", "readr", "ggplot2", "vioplot"))
```

### 2. Run the Application
You can launch either the **Classic UI** (in `app/`) or the **F1 Telemetry Dashboard UI** (in `app/pro_ui/`):

```r
library(shiny)

# Option A: Launch the Classic Single-Page UI
runApp("path/to/app")

# Option B: Launch the Modern Tabbed F1 Dashboard UI
runApp("path/to/app/pro_ui")
```
*(Alternatively, open either `app/ui.R` or `app/pro_ui/ui.R` in RStudio and click **Run App**).*

---

## 🐍 Data Pipeline (Optional)

The repository already includes the complete pre-extracted CSV datasets inside `f1_data_2025/`. To re-download or update the telemetry data from the official F1 timing feeds via `FastF1`:

```bash
pip install fastf1 pandas numpy
python downloadAllRaces.py
```

---

## 🛠️ Built With

- **[R Shiny](https://shiny.posit.co/)** — Interactive web application framework for R
- **[R Base Graphics](https://stat.ethz.ch/R-manual/R-devel/library/graphics/html/00Index.html)** — Multi-panel layouts (`par(mfrow)`), custom KDE polygons, rug plots, and OLS regression overlays
- **[FastF1](https://docs.fastf1.dev/)** — Python library for Formula 1 timing and telemetry data
