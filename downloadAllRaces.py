import fastf1
import pandas as pd
import numpy as np
import os

# Abilita la cache per non riscaricare i dati se riavvii lo script
fastf1.Cache.enable_cache('C:/Users/filip/Desktop/Altro/F1Test/f1_cache')

# ==========================================
# CONFIGURAZIONE
# ==========================================
anno = 2025

# Cartella dove salvare i CSV (verrà creata se non esiste)
output_dir = f'f1_data_{anno}'
os.makedirs(output_dir, exist_ok=True)


# ==========================================
# 1. CALENDARIO DELL'ANNO
# ==========================================
schedule = fastf1.get_event_schedule(anno, include_testing=False)
schedule_clean = schedule[['RoundNumber', 'Country', 'Location', 'EventName', 'EventDate']]
schedule_clean.to_csv(os.path.join(output_dir, f'f1_schedule_{anno}.csv'), index=False)
print(f"Calendario {anno} salvato ({len(schedule_clean)} eventi).\n")


# ==========================================
# 2. FUNZIONE PER CLASSIFICARE IL TIPO DI GIRO
# ==========================================
def classify_lap(row):
    status = str(row['TrackStatus'])

    if pd.notna(row['PitInTime']):
        return 'PitIn'   # Giro di rientro ai box
    elif pd.notna(row['PitOutTime']):
        return 'PitOut'  # Giro di uscita dai box
    elif '4' in status:
        return 'SC'      # Safety Car
    elif '6' in status or '7' in status:
        return 'VSC'     # Virtual Safety Car
    else:
        return 'Normal'  # Giro in condizioni di gara normale


# ==========================================
# 3. SCARICA OGNI GARA DEL CALENDARIO
# ==========================================
all_results = []  # Lista per raccogliere i risultati di tutte le gare
all_laps    = []  # Lista per raccogliere i giri di tutte le gare

for _, event in schedule.iterrows():
    round_num  = event['RoundNumber']
    event_name = event['EventName']
    gp_slug    = event['Location'].lower().replace(' ', '_')

    print(f"[{round_num}/{len(schedule)}] Scaricando: {event_name} ...")

    try:
        session = fastf1.get_session(anno, round_num, 'R')
        session.load(telemetry=False, weather=False, messages=False)

        # --- RESULTS ---
        results = session.results[['ClassifiedPosition', 'DriverNumber', 'Abbreviation',
                                   'TeamName', 'TeamColor', 'Time', 'Status', 'Points']].copy()
        results['RoundNumber'] = round_num
        results['EventName']   = event_name
        results['GpSlug']      = gp_slug
        all_results.append(results)

        # --- LAPS ---
        laps = session.laps[['DriverNumber', 'LapNumber', 'Position', 'LapTime',
                              'TrackStatus', 'PitInTime', 'PitOutTime', 'Compound']].copy()
        laps = laps.dropna(subset=['LapTime', 'Position']).copy()
        laps['LapTime_sec'] = laps['LapTime'].dt.total_seconds()
        laps['LapType']     = laps.apply(classify_lap, axis=1)
        laps = laps.drop(columns=['LapTime', 'TrackStatus', 'PitInTime', 'PitOutTime'])
        laps['RoundNumber'] = round_num
        laps['EventName']   = event_name
        laps['GpSlug']      = gp_slug
        all_laps.append(laps)

        print(f"    OK — {len(results)} piloti, {len(laps)} giri validi.")

    except Exception as e:
        print(f"    ERRORE: {e} — gara saltata.")

print()


# ==========================================
# 4. SALVA I FILE CSV FINALI
# ==========================================

# Un unico CSV con tutti i risultati dell'anno
if all_results:
    df_results = pd.concat(all_results, ignore_index=True)
    results_path = os.path.join(output_dir, f'f1_results_{anno}.csv')
    df_results.to_csv(results_path, index=False)
    print(f"Risultati completi salvati: {results_path}  ({len(df_results)} righe)")

# Un unico CSV con tutti i giri dell'anno
if all_laps:
    df_laps = pd.concat(all_laps, ignore_index=True)
    laps_path = os.path.join(output_dir, f'f1_laps_{anno}.csv')
    df_laps.to_csv(laps_path, index=False)
    print(f"Giri completi salvati:      {laps_path}  ({len(df_laps)} righe)")

print("\nDownload completato!")

