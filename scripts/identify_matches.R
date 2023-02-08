

library(tidyverse)

###### read data in for one mosquito ######
lrs <- read_csv(snakemake@input[[1]]) 


###### function to get matches from LRs for 1 mosquito at a given threshold ######

get_matches_1moz <- function(moz_lrs, lr_thresh, norm_thresh){
  moz_lrs %>% 
    # non-matches
    mutate(all_bad = all(log10LR < lr_thresh | is.na(log10LR) | is.infinite(log10LR)),
           note = ifelse(all_bad & is.na(note), 'All log10LR < thresh', note),
           sample_reference = ifelse(all_bad, NA, sample_reference),
           log10LR = ifelse(all_bad, NA, log10LR)) %>%
    distinct() %>%
    # potential matches - ambiguous
    filter((log10LR >= lr_thresh & !is.infinite(log10LR)) | !is.na(note)) %>% 
    mutate(prefilt_lr_norm = log10LR/sum(log10LR)*min_noc, # use logs or not? 
           all_norm_lt_thresh = all(prefilt_lr_norm < norm_thresh & is.na(note)),
           note = ifelse(all_norm_lt_thresh, 'Ambiguous matches only', note),
           sample_reference = ifelse(all_norm_lt_thresh, NA, sample_reference),
           log10LR = ifelse(all_norm_lt_thresh, NA, log10LR),
           prefilt_lr_norm = ifelse(all_norm_lt_thresh, NA, prefilt_lr_norm)) %>% 
    distinct() %>%
    # potential matches - less ambiguous
    filter(prefilt_lr_norm >= norm_thresh | !is.na(note)) %>%
    mutate(n_refs_gt_thresh = n_distinct(sample_reference[log10LR > lr_thresh])) %>%
    mutate(match_dbl = ifelse(n_refs_gt_thresh <= min_noc, 1, log10LR/sum(log10LR)*min_noc),
           note = case_when(n_refs_gt_thresh <= min_noc & is.na(note) ~ paste0('Passed all filters'),
                            n_refs_gt_thresh > min_noc & is.na(note) ~ paste0('> min NOC matches'),
                            TRUE ~ note),
           match = case_when(note == 'Passed all filters' ~ 'Yes',
                             note == '> min NOC matches' ~ 'Maybe',
                             TRUE ~ 'No')
    ) %>%
    select(sample_evidence, min_noc, m_locus_count, match, match_dbl, sample_reference, log10LR, note)
}


##### Screen the log10LR thresholds #####

  # set initial match conditions
  
  thresh = 10.5

  matches <- get_matches_1moz(moz_lrs = lrs, lr_thresh = thresh, norm_thresh = 0.5) %>%
    select(-match_dbl) %>%
    mutate(thresh_low = thresh)
  
  mht <- matches %>%
    pull(sample_reference)
  
  mlt <- "placeholder"
  
  df <- matches %>%
    mutate(thresh_low = 10.5)
  
  thresh = 10
  
  # screen thresholds
  while(!identical(mht, mlt)){
    matches <- get_matches_1moz(moz_lrs = lrs, lr_thresh = thresh, norm_thresh = 0.5) %>%
      select(-match_dbl) %>%
      mutate(thresh_low = thresh)
    
    df <- df %>%
      bind_rows(matches)
    
    mlt <- matches %>%
      pull(sample_reference)
    
    if(identical(mht, mlt) & nrow(matches) >= matches$min_noc[1] & !all(is.na(mlt))) {
      break
    }
    
    thresh = thresh - 0.5
    
    mht <- mlt
    mlt <- "placeholder"
    
    if(thresh == 0.5){
      break
    }
    
  }
   
  if(nrow(matches) < matches$min_noc[1]){
  
    temp <- df %>%
      group_by(thresh_low) %>%
      mutate(sample_reference = str_c(sample_reference, collapse = ","),
             log10LR = str_c(log10LR, collapse = ",")) %>%
      ungroup() %>%
      distinct() %>%
      filter(!is.na(sample_reference)) %>%
      arrange(thresh_low) %>%
      mutate(next_same = sample_reference == lead(sample_reference) & note == lead(note)) %>% 
      filter(next_same == TRUE) %>%
      slice_max(thresh_low) %>%
      separate_rows(sample_reference, log10LR, sep = ",") %>%
      mutate(log10LR = as.numeric(log10LR)) %>%
      select(-next_same)
    
    if(nrow(temp) > 0){
      matches <- temp
    }
      
  }


##### save matches df as a .csv ####

matches %>% write_csv(snakemake@output[[1]])




