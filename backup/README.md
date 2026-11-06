# 🏎️ 2025 Formula One Championship — Shiny App Documentation

## 1. Panoramica dell'Applicazione (Overview)

Questa applicazione **R Shiny** permette di esplorare e analizzare i dati delle gare della stagione **Formula 1 2025** (scaricati tramite la libreria Python `FastF1`).

L'utente può:
1. **Selezionare un Gran Premio** dal menu a tendina.
2. **Visualizzare un riepilogo rapido** del GP selezionato (primi 3 classificati).
3. **Selezionare un pilota** tra quelli che hanno partecipato a quel specifico GP (visualizzati tramite la loro abbreviazione a 3 lettere, es. `VER`, `LEC`, `NOR`).
4. **Generare uno Scatter Plot dei tempi sul giro** cliccando sul pulsante *"Study a driver"*, che mostra l'andamento dei tempi giro per giro distinguendo:
   - **Mescola delle gomme (`Compound`)** tramite il **colore di riempimento** del punto.
   - **Tipo di giro (`LapType`)** (Giro normale, Pit In, Pit Out, Safety Car, Virtual Safety Car) tramite la **forma** del punto.

---

## 2. Architettura e Flusso Reattivo (How It Works)

L'app è divisa nei due file classici di Shiny: [`ui.R`](file:///C:/Users/filip/Desktop/UniPd/dataVisualizazion/app/ui.R) (interfaccia utente) e [`server.R`](file:///C:/Users/filip/Desktop/UniPd/dataVisualizazion/app/server.R) (logica e calcolo).

### Flusso dei dati:
1. **Avvio (`server.R`)**: I file CSV (`f1_laps_2025.csv`, `f1_schedule_2025.csv`, `f1_results_2025.csv`) vengono caricati una sola volta in memoria insieme alle tabelle di lookup per mappare numeri, abbreviazioni e colori dei piloti.
2. **Selezione GP (`input$gp_select`)**:
   - Attiva le espressioni reattive `laps_selected_gp()`, `results_selected_gp()` e `driver_nums_in_gp()`.
   - Aggiorna automaticamente l'output testuale `output$gp_summary` e popola il menu a tendina dei piloti (`output$driver_select`) mostrando solo i piloti presenti in quella gara.
3. **Click sul pulsante (`input$show_driver_btn`)**:
   - L'`eventReactive` denominato `selected_driver_data()` cattura ("congela") i dati e l'abbreviazione del pilota selezionato solo al momento del click. In questo modo, cambiare pilota nel menu a tendina non modifica né il grafico né il titolo finché non si preme nuovamente il bottone.
   - Il `conditionalPanel` in `ui.R` (`input.show_driver_btn > 0`) rende visibile l'area del grafico dopo il primo click.

---

## 3. Dizionario dei Nomi delle Variabili (Variable Naming Guide)

Tutti i nomi delle variabili sono stati scelti in **inglese** seguendo convenzioni chiare per facilitare la spiegazione del codice:
- **`UPPER_SNAKE_CASE`** per le costanti globali.
- **`snake_case`** per dataset, variabili, espressioni reattive e ID di input/output.

### A. Costanti Globali (Global Constants)
Definite fuori dalla funzione `server` perché immutabili:

| Nome Variabile | Tipo | Descrizione |
|---|---|---|
| `COMPOUND_COLORS` | Named character vector | Associa ogni mescola (`SOFT`, `MEDIUM`, `HARD`, `INTERMEDIATE`, `WET`) al rispettivo colore nel grafico (`red`, `yellow`, `white`, `green`, `blue`). |
| `LAP_TYPE_SHAPES` | Named numeric vector | Associa ogni condizione di giro (`Normal`, `PitIn`, `PitOut`, `VSC`, `SC`) al codice `pch` di R Base (da `21` a `25`, forme piene con bordo nero e riempimento colorabile). |

---

### B. Dataset Statici e Lookup Tables
Caricati all'apertura della sessione:

| Nome Variabile | Tipo | Descrizione |
|---|---|---|
| `laps` | DataFrame (`tibble`) | Tutti i giri di tutte le gare della stagione 2025 (`f1_laps_2025.csv`). |
| `schedule` | DataFrame (`tibble`) | Il calendario ufficiale della stagione 2025 (`f1_schedule_2025.csv`). |
| `results` | DataFrame (`tibble`) | I risultati finali e le info sui piloti/team per ogni gara (`f1_results_2025.csv`). |
| `event_names` | Character vector | Lista dei nomi unici dei Gran Premi estratti da `laps$EventName`. |
| `driver_info` | DataFrame | Sottoinsieme di `results` con una riga per pilota contenente `DriverNumber`, `Abbreviation` e `TeamColor`. |
| `driver_num_by_abbr` | Named vector | **Lookup table**: ha come *nomi* le abbreviazioni (`"VER"`, `"LEC"`) e come *valori* i numeri di gara (`1`, `16`). Permette a `selectInput` di mostrare il nome all'utente ma passare il numero al server. |
| `team_color_by_abbr` | Named vector | **Lookup table**: ha come *nomi* le abbreviazioni dei piloti e come *valori* il codice esadecimale del colore del team (es. `"#E8002D"`). |

---

### C. Espressioni Reattive (`reactive` & `eventReactive`)
Funzioni dinamiche che si ricalcolano quando cambiano gli input (vanno chiamate con le parentesi `()`):

| Nome Variabile | Dipende da | Cosa restituisce |
|---|---|---|
| `laps_selected_gp()` | `input$gp_select` | Il dataframe `laps` filtrato solo per il Gran Premio selezionato. |
| `results_selected_gp()` | `input$gp_select` | Il dataframe `results` filtrato solo per il Gran Premio selezionato. |
| `driver_nums_in_gp()` | `laps_selected_gp()` | Vettore con i numeri di gara (`DriverNumber`) dei piloti che hanno corso nel GP selezionato. |
| `selected_driver_data()` | `input$show_driver_btn` | `eventReactive` che si aggiorna **solo al click del bottone**. Restituisce una `list(laps = ..., abbr = ...)` con i giri del pilota scelto e la sua abbreviazione. |

---

### D. ID di Input e Output (Comunicazione `ui.R` ↔ `server.R`)

| ID | Tipo | Descrizione |
|---|---|---|
| `gp_select` | `uiOutput` / `selectInput` | Menu a tendina per scegliere il Gran Premio. |
| `driver_select` | `uiOutput` (Contenitore UI) | Contenitore dinamico che genera il menu a tendina dei piloti. |
| `selected_driver_num` | `selectInput` (Input ID) | Il valore (numero del pilota) selezionato dall'utente nel menu dei piloti. |
| `show_driver_btn` | `actionButton` | Bottone *"Study a driver"* che avvia il calcolo e la visualizzazione dello scatter plot. |
| `gp_summary` | `verbatimTextOutput` | Riquadro di testo che stampa i primi 3 classificati del GP selezionato. |
| `lap_time_plot` | `plotOutput` | Lo scatter plot finale dei tempi sul giro del pilota. |

---

### E. Variabili Locali nei Blocchi di Rendering
Variabili temporanee usate dentro `renderUI` e `renderPlot`:

- **`active_driver_nums`**: vettore locale dei numeri dei piloti attivi nel GP corrente.
- **`driver_choices`**: sottoinsieme di `driver_num_by_abbr` filtrato per i soli piloti presenti nel GP.
- **`driver_result`**: la lista restituita da `selected_driver_data()` dentro `renderPlot`.
- **`lap_data`**: il dataframe dei giri del singolo pilota estratto da `driver_result$laps`.
- **`abbr`**: la stringa con l'abbreviazione a 3 lettere del pilota estratta da `driver_result$abbr`.
- **`team_color`**: stringa col colore esadecimale del team (ottenuta con `unname()` per rimuovere l'attributo nome).
- **`point_colors`**: vettore di colori associato a ogni giro in base alla mescola (`Compound`).
- **`point_shapes`**: vettore di codici forma (`pch`) associato a ogni giro in base al tipo di giro (`LapType`).
