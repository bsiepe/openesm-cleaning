# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
library(osfr)
source(here::here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
# download data
if(!file.exists(here("data", "raw", "0039_kuczynski_ts_raw.csv"))){
  osf_retrieve_file("https://osf.io/huz67") |>
    osf_download(path = here("data", "raw"))

  # rename data
  file_name <- osf_retrieve_file("https://osf.io/huz67") |> pull(name)
  file.rename(here("data", "raw", file_name), here("data", "raw", "0039_kuczynski_ts_raw.csv"))
}
# read data
df_raw <- read_csv(here("data", "raw", "0039_kuczynski_ts_raw.csv"))




# Cleaning ----------------------------------------------------------------
#* Column Names -----------------------------------------------------------
# rename columns
df <- df_raw |>
  janitor::clean_names()

df <- df |>
  rename(
    id = pid,
    depressed = depressedmood,
    left_out = leftout,
    social_interaction = socialintgross,
    perceived_responsiveness = ppr,
    covid_anxiety = anxietycovid
  )

#* Misc -------------------------------------------------------------------
# arrange data
df <- df |>
  arrange(id, date)

# create day column for each id
df <- df |>
  group_by(id) |>
  mutate(
    day = as.integer(date - min(date)) + 1
  ) |>
  ungroup()

# create beep = 1
df$beep <- 1

# remove weekend column
df <- df |>
  select(-weekend)


# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0039")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))

# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0039_kuczynski_ts.tsv"))
}

# Create metadata ---------------------------------------------------------
write_metadata("0039", meta_data = meta_data, variable_data = variable_data)