#################################################
#                                               #
#    Generate logLR for mosquito-human pairs    #
#                 Once Bitten                   #
#             C Markwalter & Z Lapp             #
#                January 2023                   #
#                                               #
#################################################

# Load libraries
library(tidyverse)
library(euroformix)

mozzie_ids_all <- read_csv(snakemake@input[[3]]) %>% pull(SampleName)

# Only run euroformix if mozzie profile has peaks
if(!snakemake@wildcards$moz_id %in% mozzie_ids_all){ 
  # Write empty file if mozzie profile doesn't have any peaks
  file.create(snakemake@output[[1]])
}else{

# Read in data and set parameters
freq_list <- read_rds(snakemake@input[[1]])
sample <- read_rds(snakemake@input[[4]])
refData <- read_rds(snakemake@input[[2]])
numRefs = length(refData)
kit = snakemake@params[[1]]
threads = snakemake@params[[2]]

# Set up df
LRs_1moz <- tibble(sample_evidence = character(numRefs), sample_reference = character(numRefs), log10LR = numeric(numRefs))

# Calcualte logLR for each human
for(i in 1:numRefs){
  
  output <- contLikSearch( NOC= 1, modelDegrad = TRUE, modelBWstutt = FALSE, modelFWstutt = FALSE, samples=sample, popFreq=freq_list, refData=refData ,condOrder=rep(0,length(refData)), knownRefPOI= i, prC=0.05,threshT=250,fst=0,lambda=0.01,kit=kit,nDone=2,seed=1,verbose=FALSE,alpha=0.01, difftol = 1, maxThreads=threads)
  
  LRs_1moz$sample_evidence[i] <- names(sample)
  LRs_1moz$sample_reference[i] <- names(refData)[i]
  LRs_1moz$log10LR[i] <- output$outtable[3]
  
}

# Save df as .csv
write_csv(LRs_1moz, snakemake@output[[1]])
}
          
