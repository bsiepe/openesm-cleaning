# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
library(osfr)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
# Download from OSF
if(!file.exists(here("data", "raw", "0022_menghini_ts_raw.RData"))){
  osf_retrieve_file("https://osf.io/thr48") |>
    osf_download(path = here("data", "raw"))

  # rename data
  file_name <- osf_retrieve_file("https://osf.io/thr48") |> pull(name)
  file.rename(here("data", "raw", file_name), here("data", "raw", "0022_menghini_ts_raw.RData"))
}

# load data
load(here("data", "raw", "0022_menghini_ts_raw.RData"))
df_raw <- ESMdata
rm(ESMdata)

# Cleaning ----------------------------------------------------------------
#* Column Names -----------------------------------------------------------
df <- df_raw |>
  janitor::clean_names()

# give more descriptive names
df <- df |>
  rename(
    beep = within_day,
    well = v1,
    discontent = v2,
    state = v3,
    tense = t1,
    calm = t2,
    placid = t3,
    awake = f1,
    energyless = f2,
    rested = f3,
    too_much = d1,
    work_fast = d2,
    multitasking = d3,
    hard_work = d4,
    change_task = c1,
    decide_task = c2,
    schedule_task = c3
  )






#* Misc -------------------------------------------------------------------
# order responses
df <- df |>
  arrange(id, day, beep)

# remove demographics data (is available in other dataset anyway)
df <- df |>
  select(-c(gender, age, job, job_out, job_sector, work_hours,
            no_qs, resp_rate))

# recode day of week to factor
df <- df |>
  mutate(day_of_week = factor(day_of_week, levels = c(1, 3, 5),
                              labels = c("Monday", "Wednesday", "Friday")))

# Check requirements ------------------------------------------------------
# if check_data runs without messages, the data are clean
# and should be saved as a .tsv file
check_results <- check_data(df)

# if it returns "Data are clean.", save the data
# Enter data set ID here
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0022_menghini_ts.tsv"))
}


# Create metadata ---------------------------------------------------------
metadata_url <- "https://docs.google.com/spreadsheets/d/1ALGCq_jN6I4dcjWYQ_LQe9o52DGJItwdu9fCkwOh6fg/edit?pli=1&gid=0#gid=0"
meta_data <- read_sheet(metadata_url)


# Enter dataset ID here
sheet_url <- meta_data |>
  filter(id == "0022") |>
  pull("Coding File URL")

variable_data <- read_sheet(sheet_url)

meta_json <- create_metadata_json("0022") |>
  toJSON(pretty = TRUE, auto_unbox = TRUE)

write(meta_json, here("data", "metadata", "0022_menghini_metadata.json"))
