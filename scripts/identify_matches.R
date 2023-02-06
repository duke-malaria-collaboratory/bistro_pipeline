library(tidyverse)

lrs <- read_csv('output/log10LRs.csv')

get_matches <- function(lrs, lr_thresh, norm_thresh){
  lrs %>% 
    # non-matches
    group_by(sample_evidence) %>% 
    mutate(all_bad = all(log10LR < lr_thresh | is.na(log10LR) | is.infinite(log10LR)),
           note = ifelse(all_bad & is.na(note), 'All log10LR < thresh', note),
           sample_reference = ifelse(all_bad, NA, sample_reference),
           log10LR = ifelse(all_bad, NA, log10LR)) %>% 
    distinct() %>% 
    left_join(lrs_old) %>%
    # potential matches - ambiguous
    filter((log10LR >= lr_thresh & !is.infinite(log10LR)) | !is.na(note)) %>% 
    group_by(sample_evidence) %>%
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
    select(sample_evidence, min_noc, mlocus_count, match, match_dbl, sample_reference, log10LR, note)
}


lr_thresh_options <- lapply(seq(0, 10, by = 0.5), function(thresh){
  matches <- get_matches(lrs = lrs, lr_thresh = thresh, norm_thresh = 0.5) 
  hu_matches <- matches %>% 
    group_by(match) %>% 
    summarize(hu_matches = n())
  mosq_matches <- matches %>% 
    select(sample_evidence, match) %>%
    distinct() %>% 
    group_by(match) %>% 
    summarize(mosq_matches = n())
  full_join(hu_matches, mosq_matches) %>% 
    mutate(lr_thresh = thresh, .before = 1) 
}) %>% bind_rows() %>% 
  pivot_wider(names_from = match, values_from = c(hu_matches, mosq_matches)) %>% 
  rename(no = hu_matches_No, 
         mosq_yes = mosq_matches_Yes,
         hu_yes = hu_matches_Yes,
         mosq_maybe = mosq_matches_Maybe,
         hu_maybe = hu_matches_Maybe) %>% 
  select(lr_thresh, no, mosq_yes, hu_yes, mosq_maybe, hu_maybe) %>% 
  suppressMessages()

optim_lr_thresh <- lr_thresh_options %>% 
  slice_max(hu_yes) %>% 
  slice_max(mosq_yes) %>% 
  slice_max(lr_thresh) %>% 
  pull(lr_thresh)

lr_thresh_options <- lr_thresh_options %>% 
  mutate(optim_lr_thresh = ifelse(lr_thresh == optim_lr_thresh, 'Yes', 'No'))

matches <- get_matches(lrs, lr_thresh = optim_lr_thresh, norm_thresh = 0.5)
