# load libraries
suppressPackageStartupMessages(library(tidyverse))

###### read data in for one mosquito ######
lrs <- read_csv(snakemake@input[[1]]) %>% suppressMessages() 

###### function to get matches from LRs for 1 mosquito at a given threshold ######

get_matches_1moz <- function(moz_lrs, lr_thresh, norm_thresh){
  moz_lrs %>%
    filter(log10LR >= lr_thresh) %>%
    mutate(note = ifelse(n() > min_noc, '> min NOC matches', 'Passed all filters'),
           match = ifelse(note == 'Passed all filters', 'Yes', 'No'),
           sample_reference = ifelse(note == '> min NOC matches', NA, sample_reference),
           log10LR = ifelse(note == '> min NOC matches', NA, log10LR)
          ) %>%
    select(sample_evidence, min_noc, m_locus_count, match, sample_reference, log10LR, note) %>%
    distinct() 
}

###### check for all NA log10LRs or log10LRS < 1 ######

subset_lrs <- lrs %>%
  filter(log10LR > 1 & !is.infinite(log10LR))

if(max(subset_lrs$log10LR) < 1.5){
  
  note <- lrs %>%
    mutate(note = case_when(is.na(note) ~ "All log10LR < 1.5",
                            TRUE ~ note)) %>%
    pull(note) %>%
    unique()
  
  matches <- tibble(sample_evidence = lrs$sample_evidence[1],
           min_noc = lrs$min_noc[1],
           m_locus_count = lrs$m_locus_count[1],
           match = "No",
           sample_reference = NA,
           log10LR = NA,
           note = str_c(note, collapse = ";"),
           thresh_low = NA)
  
} else {
  
  ##### Screen the log10LR thresholds #####
  
  # set initial match conditions
  
  thresh = floor(max(subset_lrs$log10LR)*2)/2 #10.5
  
  matches <- get_matches_1moz(moz_lrs = subset_lrs, lr_thresh = thresh) %>%
    mutate(thresh_low = thresh)

  mht <- matches %>%
    arrange(sample_reference) %>%
    pull(sample_reference)
  
  df <- matches %>%
    mutate(thresh_low = thresh)
  
  thresh = thresh - 0.5

  # screen thresholds
  while(TRUE){
    matches <- get_matches_1moz(moz_lrs = subset_lrs, lr_thresh = thresh) %>%
      mutate(thresh_low = thresh)

    df <- df %>%
      bind_rows(matches)
    
    thresh = thresh - 0.5

    if(thresh == 0.5){
      break
    }

    mlt <- matches %>%
      arrange(sample_reference) %>%
      pull(sample_reference)
    
    if((identical(mht, mlt) & nrow(matches) == matches$min_noc[1]) | matches$note[1] == '> min NOC matches') { # & !all(is.na(mlt))) {
      break
    }

    mht <- mlt
    
  }
 
  if(nrow(matches) < matches$min_noc[1] | matches$note[1] == '> min NOC matches' | matches$thresh_low[1] == 1){
    temp <- df %>%
      filter(note != '> min NOC matches') %>%
      group_by(thresh_low) %>%
      mutate(n_samps = n_distinct(sample_reference),
             sample_reference = str_c(sample_reference, collapse = ","),
             log10LR = str_c(log10LR, collapse = ",")) %>%
      ungroup() %>%
      distinct() %>%
      #filter(!is.na(sample_reference)) %>%
      arrange(thresh_low) %>%
      mutate(next_same = sample_reference == lead(sample_reference) & note == lead(note)) %>%
      filter(next_same) %>%
      filter(n_samps == max(n_samps)) %>%
      slice_max(thresh_low) %>%
      separate_rows(sample_reference, log10LR, sep = ",") %>%
      mutate(log10LR = as.numeric(log10LR)) %>%
      select(-c(next_same, n_samps))

    if(nrow(temp) > 0){
      matches <- temp
    }
    
  }
    
}


##### save matches df as a .csv ####

matches %>% 
  write_csv(snakemake@output[[1]])

