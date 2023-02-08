#################################################
#                                               #
#                 Combine dfs                   #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# Get list of filenames
my_filenames <- snakemake@input 

# Read log10 LR data and bind_rows
lapply(my_filenames, read_csv) %>%
  bind_rows() %>%
  write_csv(snakemake@output[[1]]) %>% 
  suppressMessages()
