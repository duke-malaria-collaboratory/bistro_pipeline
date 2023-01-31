#################################################
#                                               #
#    Shaping human and mosquito STR profiles    #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# Load STR profile data
humans <- read_csv(snakemake@input[[1]])
mozzies <- read_csv(snakemake@input[[2]])
threshT <- snakemake@params[[1]]

# Format human data
humans %>%
  distinct() %>%
  group_by(SampleName, Marker) %>%
  mutate(index = row_number()) %>%
  ungroup() %>%
  pivot_wider(names_from = index, values_from = Allele, names_prefix = "Allele") %>%
  select(SampleName, Marker, Allele1, Allele2) %>%
  ungroup() %>%
  write_csv(snakemake@output[[1]])

# Format mozzie data
mozzies %>%
  filter(Height >= threshT) %>%
  group_by(SampleName) %>%
  mutate(peaks = n_distinct(Allele, na.rm = TRUE)) %>%
  filter(peaks != 0) %>%
  select(-peaks) %>%
  arrange(Allele) %>%
  group_by(SampleName, Marker) %>%
  mutate(index = row_number()) %>%
  pivot_wider(names_from = index, values_from = c(Allele, Height), names_sep = "") %>%
  ungroup() %>%
  write_csv(snakemake@output[[2]])

# Get minimum number of contributors for each mozzie
mozzies %>%
    group_by(SampleName, Marker) %>%
    mutate(peaks = n_distinct(Allele, na.rm = TRUE)) %>%
    group_by(SampleName) %>%
    slice_max(peaks) %>%
    mutate(min_noc = ceiling(peaks/2)) %>%
    select(SampleName, min_noc) %>%
    unique() %>%  
    write_csv(snakemake@output[[3]])
