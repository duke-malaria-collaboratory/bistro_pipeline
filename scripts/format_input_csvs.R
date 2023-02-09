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
humans <- read_csv(snakemake@input[[1]]) %>% suppressMessages()
mozzies <- read_csv(snakemake@input[[2]]) %>% suppressMessages()

# Format human data
hu_formatted <- humans %>%
  distinct() %>% # in case duplicate people
  group_by(SampleName, Marker) %>%
  mutate(index = row_number()) %>%
  pivot_wider(names_from = index, values_from = Allele, names_prefix = "Allele") %>%
  select(SampleName, Marker, Allele1, Allele2)

# Next few steps remove twins 
hu_allele_strings <- hu_formatted %>% 
  group_by(SampleName) %>% 
  summarize(all_alleles = str_c(paste0(Allele1, ',', Allele2), collapse = ';')) 

hu_string_dups <- hu_allele_strings %>%
  group_by(all_alleles) %>% 
  tally() %>% 
  filter(n > 1) %>% 
  pull(all_alleles)

print(paste0('Identified ', length(hu_string_dups), ' human allele profiles that appear more than once (likely twins). These are being removed.'))

hu_formatted %>% 
  left_join(hu_allele_strings) %>% 
  filter(!(all_alleles %in% hu_string_dups)) %>% 
  select(-all_alleles) %>%
  write_csv(snakemake@output[[1]])

# Format mozzie data
mozzies %>%
  group_by(SampleName) %>%
  mutate(peaks = n_distinct(Allele, na.rm = TRUE)) %>%
  filter(peaks != 0) %>%
  select(-peaks) %>%
  arrange(Allele) %>%
  group_by(SampleName, Marker) %>%
  mutate(index = row_number()) %>%
  pivot_wider(names_from = index, values_from = c(Allele, Height), names_sep = "") %>%
  write_csv(snakemake@output[[2]])
