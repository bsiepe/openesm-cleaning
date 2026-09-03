# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
# Read in data
df_raw <- read.csv(here("data", "raw", "0014_habets_ts_raw.csv"))




# Cleaning ----------------------------------------------------------------
#* Column Names -----------------------------------------------------------
# Rename columns
df <- df_raw |>
  janitor::clean_names() |>
  rename(
    beep_start = beep_time_start,
    beep_end = beep_time_end,
    well = mood_well,
    down = mood_down,
    frightened = mood_fright,
    tense = mood_tense,
    sleepy = phy_sleepy,
    tired = phy_tired,
    cheerful = mood_cheerf,
    relaxed = mood_relax,
    concentrate = thou_concent,
    hallucinations = pat_hallu,
    parkinson_onoff = sanpar_onoff,
    parkinson_medication = sanpar_medic,
    beep_disturbing = beep_disturb,
    mor_slept_well = mor_sleptwell
  )


#* Misc -------------------------------------------------------------------
# convert two beep columns to PosixCt
df <- df |>
  mutate(
    beep_start = as.POSIXct(beep_start, format = "%Y-%m-%d %H:%M:%S"),
    beep_end = as.POSIXct(beep_end, format = "%Y-%m-%d %H:%M:%S")
  )


# add day variable for each person
df <- df |>
  group_by(id) |>
  mutate(
    day = as.integer(as.Date(beep_start) - min(as.Date(beep_start))) + 1
  ) |>
  ungroup()

# add beep variable
df$beep <- NA


# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0014")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))


# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0014_habets_ts.tsv"))
}


# Create metadata ---------------------------------------------------------
write_metadata("0014", meta_data = meta_data, variable_data = variable_data)
