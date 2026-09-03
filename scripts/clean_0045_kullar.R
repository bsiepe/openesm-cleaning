# Packages ----------------------------------------------------------------
library(tidyverse)
library(here)
library(googlesheets4)
library(jsonlite)
source(here("scripts", "functions_data.R"))



# Data --------------------------------------------------------------------
# download directly from GitHub
if(!file.exists(here("data", "raw", "0045_kullar_ts_raw.csv"))){
  download.file("https://raw.githubusercontent.com/mkullar/DataDrivenEmotionDynamics/refs/heads/main/esmdata.csv",
                destfile = here("data", "raw", "0045_kullar_ts_raw.csv"))
}
df_raw <- read.csv(here("data", "raw", "0045_kullar_ts_raw.csv"))

# Cleaning ----------------------------------------------------------------
#* Column Names -----------------------------------------------------------
# rename columns
df <- df_raw |>
  janitor::clean_names() |>
  rename(
    id = moniker,
    happy = happy_e,
    mind_wandering = m_woccur
  )


#* Misc -------------------------------------------------------------------
# split time into day and beep number at the "."
df <- df |>
  separate_wider_delim(time,
                       delim = ".",
                       names = c("day", "beep"))


# Read metadata -----------------------------------------------------------
# loaded before checking so check_data() can cross-check data against metadata
meta_data <- read_sheet(METADATA_URL)
dataset_info <- meta_data |>
  filter(dataset_id == "0045")
variable_data <- read_sheet(pull(dataset_info, "Coding File URL"))

# Check requirements ------------------------------------------------------
# errors abort; warnings flag likely problems but still allow saving
check_results <- check_data(df, dataset_info, variable_data)

# if it returns "Data are clean.", save the data
if(check_results == "Data are clean."){
  write_tsv(df, here("data", "clean", "0045_kullar_ts.tsv"))
}

# Create metadata ---------------------------------------------------------
write_metadata("0045", meta_data = meta_data, variable_data = variable_data)