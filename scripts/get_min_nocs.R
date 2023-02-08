#################################################
#                                               #
#   Get minimum number of contributors by moz   #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# Get minimum number of contributors for each mozzie
read_csv(snakemake@input[[1]]) %>%
    filter(Height >= snakemake@params[[1]]) %>%
    group_by(SampleName, Marker) %>%
    mutate(peaks = n_distinct(Allele, na.rm = TRUE)) %>%
    group_by(SampleName) %>%
    mutate(m_locus_count = n_distinct(Marker, na.rm = TRUE)) %>%
    slice_max(peaks) %>%
    mutate(min_noc = ceiling(peaks/2),
           efm_noc = min(min_noc, 3)) %>%
    select(SampleName, m_locus_count, min_noc, efm_noc) %>%
    unique() %>%  
    write_csv(snakemake@output[[1]])
