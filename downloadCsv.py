import fastf1
import pandas as pd
import numpy as np

# Abilita la cache per non riscaricare i dati se riavvii lo script
fastf1.Cache.enable_cache('C:/Users/filip/Desktop/Altro/F1Test/f1_cache') 
anno = 2026
gran_premio = 'Madrid' # Puoi usare il nome, il luogo o il numero del round

# Prefisso per i nomi dei file (es. "monza_2025")
gp_slug = f"{gran_premio.lower().replace(' ', '_')}_{anno}"

# ==========================================
# 1. OTTENERE GLI EVENTS (CALENDARIO)
# ==========================================
schedule = fastf1.get_event_schedule(anno)
schedule = schedule[['RoundNumber', 'Country', 'Location', 'EventName', 'EventDate']]
schedule.to_csv(f'f1_schedule_{anno}.csv', index=False)
print("Calendario salvato.")
# ==========================================
# 2. OTTENERE LA CLASSIFICA FINALE (RESULTS)
# ==========================================
session = fastf1.get_session(anno, gran_premio, 'R')
session.load(telemetry=False, weather=False, messages=False)
results = session.results
results_clean = results[['ClassifiedPosition', 'DriverNumber', 'Abbreviation', 'TeamName', 'Time', 'Status', 'Points']]
results_clean.to_csv(f'f1_results_{gp_slug}.csv', index=False)
print("Classifica finale salvata.")
# ==========================================
# 3. POSIZIONI GIRO PER GIRO PER LA GARA (CON STATUS)
# ==========================================
laps = session.laps
# Estraiamo le colonne necessarie, includendo TrackStatus e i tempi dei box
laps_data = laps[['DriverNumber', 'LapNumber', 'Position', 'LapTime', 'TrackStatus', 'PitInTime', 'PitOutTime', 'Compound']]
# ATTENZIONE: Ora usiamo dropna solo su LapTime e Position. 
# Se facessimo un dropna() generale, cancellerebbe tutti i giri normali (che non hanno un PitInTime!)
laps_data = laps_data.dropna(subset=['LapTime', 'Position']).copy()
# Convertiamo il LapTime in secondi
laps_data['LapTime_sec'] = laps_data['LapTime'].dt.total_seconds()
# Funzione per classificare il tipo di giro
def classify_lap(row):
    status = str(row['TrackStatus'])
    
    if pd.notna(row['PitInTime']):
        return 'PitIn'  # Giro di rientro ai box
    elif pd.notna(row['PitOutTime']):
        return 'PitOut' # Giro di uscita dai box
    elif '4' in status:
        return 'SC'     # Safety Car
    elif '6' in status or '7' in status:
        return 'VSC'    # Virtual Safety Car
    else:
        return 'Normal' # Giro in condizioni di gara normale
# Applichiamo la funzione per creare una nuova colonna 'LapType'
laps_data['LapType'] = laps_data.apply(classify_lap, axis=1)
# Rimuoviamo le colonne che non ci servono più per Shiny
laps_clean = laps_data.drop(columns=['LapTime', 'TrackStatus', 'PitInTime', 'PitOutTime'])
laps_clean.to_csv(f'f1_lap_positions_{gp_slug}.csv', index=False)
print("Posizioni giro per giro salvate con classificazione del giro.")