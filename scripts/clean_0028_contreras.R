# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
library(osfr)
library(haven)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
# download data
if(!file.exists(here("data", "raw", "0028_contreras_ts_raw.sav"))){
  osf_retrieve_file("https://osf.io/8ewyn") |>
    osf_download(path = here("data", "raw"))

  # rename data
  file_name <- osf_retrieve_file("https://osf.io/8ewyn") |> pull(name)
  file.rename(here("data", "raw", file_name), here("data", "raw", "0028_contreras_ts_raw.sav"))
}

df_raw <- read_sav(here("data", "raw", "0028_contreras_ts_raw.sav"))


# Cleaning ----------------------------------------------------------------

#* Column Names -----------------------------------------------------------
# rename columns
df <- df_raw |>
  janitor::clean_names() |>
  rename(id = subject,
         sad = sadness,
         useless = se1,
         manage_well = se2,
         no_trust = par1,
         harm = par2,
         criticism = par3,
         avoid = ea)


#* Misc -------------------------------------------------------------------
# remove average columns
df <- df |>
  select(-contains("aver"))





# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0028")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))

# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0028_contreras_ts.tsv"))
}

# Create metadata ---------------------------------------------------------
write_metadata("0028", meta_data = meta_data, variable_data = variable_data)