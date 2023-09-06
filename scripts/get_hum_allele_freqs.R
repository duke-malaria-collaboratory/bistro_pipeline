# Generate human frequency table
readr::read_csv(snakemake@input[[1]]) |>
  bistro::rm_dups() |>
  bistro::calc_allele_freqs() |>
  readr::write_csv(snakemake@output[[1]]) |>
  suppressMessages()
