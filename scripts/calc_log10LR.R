# Load library
library(bistro)

# Read in data and set parameters
bm_id <- snakemake@wildcards$bm_id
threshT <- snakemake@params$peak_thresh
bm_data <- readr::read_csv(snakemake@input$bm_profiles_csv) |>
  dplyr::filter(SampleName == bm_id) |>
  bistro::filter_peaks(threshT) |>
  suppressMessages()
hu_data <- readr::read_csv(snakemake@input$hum_profiles_csv) |>
  suppressMessages()
if(snakemake@params$rm_twins) hu_data <- bistro::rm_twins(hu_data)
allele_freqs <- readr::read_csv(snakemake@input$hum_allele_freqs_csv) |>
  suppressMessages()
kit <- snakemake@params$kit
difftol <- snakemake@params$difftol
threads <- snakemake@params$threads
seed <- snakemake@params$seed
time_limit <- snakemake@params$time_limit # in minutes
modelDegrad <- as.logical(snakemake@params$model_degrad)
modelBWstutt <- as.logical(snakemake@params$model_bw_stutt)
modelFWstutt <- as.logical(snakemake@params$model_fw_stutt)

# Calcualte logLR for each human and save to csv
bistro::calc_log10_lrs(bloodmeal_profiles = bm_data,
               human_profiles = hu_data,
               pop_allele_freqs = allele_freqs,
               kit = kit,
               peak_thresh = threshT,
               bloodmeal_id = bm_id,
               model_degrad = modelDegrad,
               model_bw_stutt = modelBWstutt,
               model_fw_stutt = modelFWstutt,
               difftol = difftol,
               threads = threads,
               seed = seed,
               time_limit = time_limit) |>
   readr::write_csv(snakemake@output[[1]])
