#################################################
#                                               #
#    Get human population allele frequencies    #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# Generate human frequency table
read_csv(snakemake@input[[1]]) %>%
  distinct() %>% # in case duplicate people
  group_by(Marker, Allele) %>%
  mutate(allele_count = n()) %>%
  group_by(Marker) %>%
  mutate(locus_n = n()) %>%
  ungroup() %>%
  mutate(freq = allele_count/locus_n) %>%
  select(Marker, Allele, freq) %>%
  distinct() %>%
  pivot_wider(names_from = "Marker", values_from = freq) %>%
  write_csv(snakemake@output[[1]]) %>%
  suppressMessages()
