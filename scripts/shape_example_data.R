#################################################
#                                               #
#    Re-shaping euroformix tutorial data for    #
#                bistro pipeline                #
#             C Markwalter & Z Lapp             #
#                  March 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))


# Evidence

evidence <- read_delim("../example_data/from_euroformix/stain.txt") %>%
  select(-ADO, -UD1, -`...17`) %>%
  mutate(across(starts_with("Allele"), as.character), across(starts_with("Height"), as.character)) %>%
  pivot_longer(cols = c(starts_with("Allele"), starts_with("Height")), names_to = "names", values_to = "value") %>%
  drop_na() %>%
  filter(str_detect(names, "Allele")) %>%
  mutate(index = substr(names, 8,8)) %>%
  select(-names) %>%
  rename(Allele = value) %>%
  left_join(read_delim("../example_data/from_euroformix/stain.txt") %>%
              select(-ADO, -UD1, -`...17`) %>%
              mutate(across(starts_with("Allele"), as.character), across(starts_with("Height"), as.character)) %>%
              pivot_longer(cols = c(starts_with("Allele"), starts_with("Height")), names_to = "names", values_to = "value") %>%
              drop_na() %>%
              filter(str_detect(names, "Height")) %>%
              mutate(index = substr(names, 8,8)) %>%
              select(-names) %>%
              rename(Height = value)) %>%
  select(-index) %>%
  rename(SampleName = `Sample Name`) %>%
  arrange(SampleName, Marker, Allele)

write_csv(evidence, file = "../example_data/bistro_input/evidence.csv")


# Reference

reference <- read_delim("../example_data/from_euroformix/databaseESX17.txt") %>%
  pivot_longer(cols = starts_with("Allele"), names_to = "name", values_to = "Allele") %>%
  select(-name) %>%
  rename(SampleName = `Sample Name`) %>%
  arrange(SampleName, Marker, Allele)

write_csv(reference, file = "../example_data/bistro_input/reference_database.csv")

# Allele frequencies

freqs <- read_csv("../example_data/from_euroformix/ESX17_Norway.csv")

write_csv(freqs, file = "../example_data/bistro_input/allele_freqs.csv")
