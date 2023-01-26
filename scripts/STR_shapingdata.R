#################################################
#                                               #
#    Shaping human and mosquito STR profiles    #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
library(tidyverse)
library(euroformix)

# Load STR profile data
humans <- read_csv("data/STR_human_database_long.csv")
mozzies <- read_csv("data/STR_all_mozzies_long.csv")

# Shaping mosquito data
mozzies_euro <- mozzies %>%
  select(mozzie_id, Locus, Allele, RFU) %>%
  group_by(mozzie_id) %>%
  mutate(peaks = n_distinct(Allele, na.rm = TRUE)) %>%
  filter(peaks != 0) %>%
  select(-peaks) %>%
  arrange(Allele) %>%
  rename("SampleName" = "mozzie_id", "Marker" = "Locus") %>%
  group_by(SampleName, Marker) %>%
  mutate(index = row_number()) %>%
  rename("Height" = "RFU") %>%
  pivot_wider(names_from = index, values_from = c(Allele, Height), names_sep = "") %>%
  ungroup() %>%
  data.frame() %>%
  sample_tableToList()

# Saving a separate .rds file for each mozzie

for(i in 1:length(mozzies_euro)){
  saveRDS(mozzies_euro[i], paste0("data/mozzies/", names(mozzies_euro)[i], "_profile.rds"))
}

# Shaping human data
Hu_euro <- humans %>%
  select(M_ID, Marker, alleles) %>%
  distinct() %>%
  group_by(M_ID, Marker) %>%
  mutate(index = row_number()) %>%
  ungroup() %>%
  pivot_wider(names_from = index, values_from = alleles, names_prefix = "Allele ") %>%
  rename("Sample Name" = "M_ID")  %>%
  select(-`Allele 3`) %>%
  ungroup() %>%
  data.frame() %>%
  sample_tableToList()

# Save human RDS
saveRDS(Hu_euro, "data/Hu_refData.rds")

# Generate allele frequency data
freq_list <- freqImport("data/Hu_allele_freq.csv")[[1]]

# Save formatted allele frequency table
saveRDS(freq_list, "data/Hu_allele_freq.rds")
