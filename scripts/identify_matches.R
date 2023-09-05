# Identify matches for one bloodmeal
lrs <- readr::read_csv(snakemake@input[[1]]) |>
  bistro::identify_matches() |>
  readr::write_csv(snakemake@output[[1]]) |>
  suppressMessages()

