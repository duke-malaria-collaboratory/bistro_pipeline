#################################################
#                                               #
#              Combine logLR dfs                #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
library(tidyverse)

# Get list of filenames
my_filenames <- paste0("data/mozzies/", list.files(path = "data/mozzies/generated_tables", pattern = "\\_matches.csv$"))

# Read log10 LR data and bind_rows
my_data <- lapply(my_filenames, read_csv) %>%
  bind_rows()
