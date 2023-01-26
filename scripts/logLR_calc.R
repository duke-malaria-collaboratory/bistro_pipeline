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

# Read in data and set parameters
freq_list <- readRDS("data/Hu_allele_freq.rds")
sample <- readRDS(paste0("data/mozzies/", names(mozzies_euro)[i], "_profile.rds")) ### WILL NEED TO CHANGE!!!
refData <- readRDS("data/Hu_refData.rds")
numRefs = length(refData)
kit = "GenePrint10"

# Set up df
LRs_1moz <- tibble(mozzie_id = character(numRefs), M_ID = character(numRefs), log10LR = numeric(numRefs))

# Calcualte logLR for each human
for(i in 1:numRefs){
  
  output <- contLikSearch( NOC= 1, modelDegrad = TRUE, modelBWstutt = FALSE, modelFWstutt = FALSE, samples=sample, popFreq=freq_list, refData=refData ,condOrder=rep(0,length(refData)), knownRefPOI= i, prC=0.05,threshT=250,fst=0,lambda=0.01,kit=kit,nDone=2,seed=1,verbose=FALSE,alpha=0.01, difftol = 1)
  
  LRs_1moz$mozzie_id[i] <- names(sample)
  LRs_1moz$M_ID[i] <- names(refData)[i]
  LRs_1moz$log10LR[i] <- output$outtable[3]
  
}

# Save df as .csv
write_csv(LRs_1moz, paste0("data/mozzies/", names(sample), "_matches.csv"))

          