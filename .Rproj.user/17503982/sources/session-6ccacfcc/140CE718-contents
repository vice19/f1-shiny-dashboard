setwd("C:/Users/filip/Desktop/UniPd/dataVisualizazion/app")
library(readr)

laps_data <- read_csv("f1_lap_positions_madrid_2026.csv")
results_data <- read_csv("f1_results_madrid_2026.csv")

# Mappa colori ufficiali F1 per mescola
compound_colors <- c(
  "SOFT"         = "red",
  "MEDIUM"       = "yellow",
  "HARD"         = "white",
  "INTERMEDIATE" = "green",
  "WET"          = "blue"
)


df <- laps_data[laps_data$DriverNumber == 4 & laps_data$LapType == "Normal" , ]
# Ricava il colore per ogni giro in base al Compound
colors <- compound_colors[df$Compound]

plot(df$LapTime_sec, xlab = "Giro", ylab = "Tempo (sec)", pch = 21, bg  = colors, col = "black", cex = 1)
# legend("topright", legend = names(compound_colors), pch = 21, pt.bg  = compound_colors,col = "black", pt.cex = 1) 

laps_medium = df[df$Compound=="MEDIUM",]
laps_hard = df[df$Compound=="HARD",]
laps_soft = df[df$Compound=="SOFT",]

lm_soft = lm(laps_soft$LapTime_sec ~ laps_medium$LapNumber)
lm_medium = lm(laps_medium$LapTime_sec ~ laps_medium$LapNumber)
lm_hard = lm(laps_hard$LapTime_sec ~ laps_hard$LapNumber)

abline(lm_hard, col = "black", lwd = 3)
abline(lm_hard, col = compound_colors["SOFT"], lwd = 1.5)

abline(lm_medium, col = "black", lwd = 3)
abline(lm_medium, col = compound_colors["MEDIUM"], lwd = 1.5)

abline(lm_hard, col = "black", lwd = 3)
abline(lm_hard, col = compound_colors["HARD"], lwd = 1.5)




