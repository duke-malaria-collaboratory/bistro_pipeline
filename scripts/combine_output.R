# Read log10 LR data and bind_rows
lapply(snakemake@input, readr::read_csv) |>
  dplyr::bind_rows() |>
  readr::write_csv(snakemake@output[[1]]) |>
  suppressMessages()
