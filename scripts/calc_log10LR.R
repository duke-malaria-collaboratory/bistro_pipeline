#################################################
#                                               #
#    Generate logLR for mosquito-human pairs    #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
suppressPackageStartupMessages(library(tidyverse))
library(euroformix)

mozzie_ids_all <- read_csv(snakemake@input[[3]]) %>% pull(SampleName) %>% unique() %>% suppressMessages()

noc_dat <- read_csv(snakemake@input[[4]]) %>%
         filter(SampleName == snakemake@wildcards$moz_id) %>% suppressMessages()
m_locus_count <- noc_dat %>% pull(m_locus_count)
min_noc <- noc_dat %>% pull(min_noc)

# Only run euroformix if mozzie profile has peaks
if(!snakemake@wildcards$moz_id %in% mozzie_ids_all){
  # Write empty file if mozzie profile doesn't have any peaks
  tibble(sample_evidence = snakemake@wildcards$moz_id, 
         sample_reference = NA,
         m_locus_count = m_locus_count, 
         min_noc = min_noc,
         efm_noc = NA,
         log10LR = NA,
         note = 'No peaks') %>%
  write_csv(snakemake@output[[1]])
}else{

# Read in data
freq_list <- read_rds(snakemake@input[[1]]) %>% suppressMessages()
sample <- read_rds(snakemake@input[[5]]) %>% suppressMessages()

# Don't run euroformix if none of the peaks in the sample are in the reference dataset
freq_df <- freq_list %>%
    map(enframe) %>%
    bind_rows(.id='Marker') %>% 
    rename(adata = name, freq = value)
no_ref_peaks <- sample[[1]] %>%
    map(as_tibble) %>%
    bind_rows(.id='Marker') %>%
    left_join(freq_df) %>%
    summarize(all_na = all(is.na(freq))) %>%
    pull(all_na)

if(no_ref_peaks){
  # Write empty file if mozzie profile doesn't have any peaks in ref db
  tibble(sample_evidence = snakemake@wildcards$moz_id,
         m_locus_count = m_locus_count,
         sample_reference = NA,
         min_noc = min_noc,
         efm_noc = NA,
         log10LR = NA,
         note = 'No peaks in reference database') %>%
  write_csv(snakemake@output[[1]])
}else{

# Read in more data and set parameters
refData <- read_rds(snakemake@input[[2]]) %>% suppressMessages()
numRefs <- length(refData)
kit <- snakemake@params[[1]]
#noc <- as.numeric(snakemake@params[[2]])
efm_noc <- noc_dat %>% pull(efm_noc) 
threshT <- snakemake@params[[2]]
difftol <- snakemake@params[[3]]
threads <- snakemake@params[[4]]
seed <- snakemake@params[[5]]
time_limit <- snakemake@params[[6]] # in seconds

cat(paste0('NOC: ', efm_noc, '\n'))
cat(paste0('Number of references: ', numRefs, '\n'))
cat(paste0('Calculating log10LRs for each reference\n'))

# Set up df
LRs_1moz <- tibble(sample_evidence = character(numRefs), m_locus_count = m_locus_count, sample_reference = NA, min_noc = min_noc,  efm_noc = efm_noc, log10LR = NA, note = NA)

# Calcualte logLR for each human
time_try <- tryCatch({
{
setTimeLimit(time_limit) # in seconds
for(i in 1:numRefs){
  print(i)  
  out <- tryCatch({output <- contLikSearch(NOC=efm_noc, modelDegrad=TRUE, modelBWstutt=FALSE, modelFWstutt=FALSE, samples=sample, popFreq=freq_list, refData=refData, condOrder=rep(0,length(refData)), knownRefPOI=i, prC=0.05, threshT=threshT, lambda=0.01, kit=kit, nDone=2, seed=seed, difftol=difftol, maxThreads=threads, verbose=FALSE)
    output$outtable[3]
    },
    error = function(cond) return('euroformix error')
)
  LRs_1moz$sample_evidence[i] <- names(sample)
  LRs_1moz$sample_reference[i] <- names(refData)[i]
  LRs_1moz$log10LR[i] <- out
  if(out == 'euroformix error'){
     LRs_1moz$note[i] <- 'euroformix error'
     LRs_1moz$log10LR[i] <- NA
  }
  
}
'Worked'
}
},
error = function(cond) return('Timed out')
)

# Save df as .csv
LRs_1moz %>% 
    mutate(note = ifelse(is.na(log10LR) & time_try == 'Timed out', 'Timed out', note)) %>%
    write_csv(snakemake@output[[1]])
}
} 
