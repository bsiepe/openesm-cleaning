# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
library(readxl)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
df_raw <- read_excel(here::here("data", "raw", "0029_drukker_ts_raw.xls"))


# Cleaning ----------------------------------------------------------------

#* Column Names -----------------------------------------------------------
# rename columns
df <- df_raw |>
  janitor::clean_names() |>
  # remove "mood_" from all variable names
  rename_with(~str_remove(., "mood_")) |>
  rename(
    day = dayno,
    beep = beepno,
    phy_abd = phyabd,
    enthusiastic = enthous,
    irritated = irritat,
    cheerful = cheerf,
    rushed = rush
  )


#* Misc -------------------------------------------------------------------
# split off demographic data
df_demographic <- df |>
  distinct(id, jtvtrauma)

# save demographic data
write_tsv(df_demographic, here("data", "clean", "0029_drukker_static.tsv"))

# remove demographic column from main data
df <- df |>
  select(-jtvtrauma)

# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0029")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))

# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0029_drukker_ts.tsv"))
}

# Create metadata ---------------------------------------------------------
write_metadata("0029", meta_data = meta_data, variable_data = variable_data)