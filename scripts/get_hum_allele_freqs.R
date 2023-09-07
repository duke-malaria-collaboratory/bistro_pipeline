# Generate human frequency table
readr::read_csv(snakemake@input[[1]]) |>
  bistro::calc_allele_freqs(rm_markers = c('AMEL') |>
  readr::write_csv(snakemake@output[[1]]) |>
  suppressMessages()
