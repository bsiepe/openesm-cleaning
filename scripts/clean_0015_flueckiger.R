# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
library(haven)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
df_raw <- read_sav(here::here("data", "raw", "0015_flueckiger_ts_raw.sav"))

# Cleaning ----------------------------------------------------------------
#* Column Names -----------------------------------------------------------
df <- df_raw |>
  janitor::clean_names() |>
  rename(
    sleep_quality = sq,
    physical_activity = phys_act,
    learning_goal_achievement = lga
  )


#* Misc -------------------------------------------------------------------
# add beep column (once per day)
df <- df |>
  mutate(beep = 1)


# recode -99 to NA
df <- df |>
  mutate(across(where(is.numeric), ~na_if(., -99))) |>
  mutate(across(where(is.character), ~na_if(., "-99")))

# arrange data set
df <- df |>
  arrange(id, day)


# split off demograhpic data
cols_demo <- c("bdi", "age", "sex", "sem", "exam", "hsg")

df_demographics <- df |>
  group_by(id) |>
  distinct(across(all_of(cols_demo))) |>
  ungroup()

# save demographic data
write_tsv(df_demographics, here("data", "clean", "0015_flueckiger_static.tsv"))

# remove demographic columns from main data
df <- df |>
  select(-all_of(cols_demo))


# Check requirements ------------------------------------------------------
# if check_data runs without messages, the data are clean
# and should be saved as a .tsv file
# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0015")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))


# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0015_flueckiger_ts.tsv"))
}


# Create metadata ---------------------------------------------------------
write_metadata("0015", meta_data = meta_data, variable_data = variable_data)
