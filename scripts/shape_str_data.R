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
library(euroformix)

# Load STR profile data
humans <- read_csv(snakemake@input[[2]]) %>% suppressMessages()
mozzies <- read_csv(snakemake@input[[3]]) %>% suppressMessages()
mozzie_ids_all <- read_csv(snakemake@input[[4]]) %>% pull(SampleName) %>% suppressMessages()

# Shaping mosquito data
mozzies_euro <- mozzies %>%
  data.frame() %>%
  sample_tableToList()

# Saving a separate rds file for each mozzie
for(i in mozzie_ids_all[!mozzie_ids_all %in% mozzies$SampleName]){
  # Write empty file if mozzie profile doesn't have any peaks
  file.create(paste0("output/data/mozzies/", i, "_profile.rds"))
}

for(i in 1:length(mozzies_euro)){
  write_rds(mozzies_euro[i], paste0("output/data/mozzies/", names(mozzies_euro)[i], "_profile.rds")) # change file path to be parameter
}

# Shaping human data
Hu_euro <- humans %>%
  data.frame() %>% 
  sample_tableToList()

# Save human rds
write_rds(Hu_euro, snakemake@output[[2]])

# Generate allele frequency data
freq_list <- freqImport(snakemake@input[[1]])[[1]]

# Save formatted allele frequency table
write_rds(freq_list, snakemake@output[[1]])
