# Load library
library(bistro)

# Read in data and set parameters
bm_id <- snakemake@wildcards$bm_id
peak_thresh <- snakemake@params$peak_thresh
bm_data <- readr::read_csv(snakemake@input$bm_profiles_csv) |>
  dplyr::filter(SampleName == bm_id) |>
  bistro::rm_dups() |>
  bistro::filter_peaks(peak_thresh) |>
  suppressMessages()
hu_data <- readr::read_csv(snakemake@input$hum_profiles_csv) |>
  bistro::rm_dups() |>
  suppressMessages()
if (snakemake@params$rm_twins)
  hu_data <- bistro::rm_twins(hu_data)
allele_freqs <-
  readr::read_csv(snakemake@input$hum_allele_freqs_csv) |>
  suppressMessages()
kit <- snakemake@params$kit
difftol <- snakemake@params$difftol
threads <- snakemake@params$threads
seed <- snakemake@params$seed
time_limit <- snakemake@params$time_limit # in minutes
model_degrad <- as.logical(snakemake@params$model_degrad)
model_bw_stutt <- as.logical(snakemake@params$model_bw_stutt)
model_fw_stutt <- as.logical(snakemake@params$model_fw_stutt)

# Calcualte logLR for each human and save to csv
bistro::calc_log10_lrs(
  bloodmeal_profiles = bm_data,
  human_profiles = hu_data,
  pop_allele_freqs = allele_freqs,
  kit = kit,
  peak_thresh = peak_thresh,
  bloodmeal_id = bm_id,
  model_degrad = model_degrad,
  model_bw_stutt = model_bw_stutt,
  model_fw_stutt = model_fw_stutt,
  difftol = difftol,
  threads = threads,
  seed = seed,
  time_limit = time_limit
) |>
  readr::write_csv(snakemake@output[[1]])
