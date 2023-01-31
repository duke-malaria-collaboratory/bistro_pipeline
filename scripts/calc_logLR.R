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

noc <- as.numeric(snakemake@params[[2]])

mozzie_ids_all <- read_csv(snakemake@input[[3]]) %>% pull(SampleName) %>% unique()

# Only run euroformix if mozzie profile has peaks
if(!snakemake@wildcards$moz_id %in% mozzie_ids_all){ 
  # Write empty file if mozzie profile doesn't have any peaks
  tibble(sample_evidence = snakemake@wildcards$moz_id, 
         sample_reference = NA, 
         noc = noc,
         log10LR = NA,
         note = 'No peaks') %>% 
  write_csv(snakemake@output[[1]])
}else{

# Read in data and set parameters
freq_list <- read_rds(snakemake@input[[1]])
sample <- read_rds(snakemake@input[[4]])
refData <- read_rds(snakemake@input[[2]])
numRefs <- length(refData)
kit <- snakemake@params[[1]]
#noc <- as.numeric(snakemake@params[[2]])
#noc <- read_csv(snakemake@input[[4]]) %>% 
#         filter(SampleName == snakemake@wildcards$moz_id) %>%
#         pull(efm_noc) 
threshT <- snakemake@params[[3]]
difftol <- snakemake@params[[4]]
threads <- snakemake@params[[5]]
seed <- snakemake@params[[6]]

cat(paste0('NOC: ', noc, '\n'))
cat(paste0('Number of references: ', numRefs, '\n'))
cat(paste0('Calculating log10LRs for each reference\n'))

# Set up df
LRs_1moz <- tibble(sample_evidence = character(numRefs), sample_reference = NA, noc = noc, log10LR = NA, note = NA)

# Calcualte logLR for each human
for(i in 1:numRefs){
  print(i)  
  output <- contLikSearch(NOC=noc, modelDegrad=TRUE, modelBWstutt=FALSE, modelFWstutt=FALSE, samples=sample, popFreq=freq_list, refData=refData, condOrder=rep(0,length(refData)), knownRefPOI=i, prC=0.05, threshT=threshT, lambda=0.01, kit=kit, nDone=2, seed=seed, difftol=difftol, maxThreads=threads, verbose=FALSE)
  
  LRs_1moz$sample_evidence[i] <- names(sample)
  LRs_1moz$sample_reference[i] <- names(refData)[i]
  LRs_1moz$log10LR[i] <- output$outtable[3]
  #LRs_1moz$log10LR_2[i] <- output$outtable[2,3]
  #LRs_1moz$log10LR_3[i] <- output$outtable[3,3]
 
}

# Save df as .csv
write_csv(LRs_1moz, snakemake@output[[1]])
}
          
