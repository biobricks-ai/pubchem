library(purrr)
library(fs)
library(arrow)
library(readr)
library(dplyr)
library(plyr)

outdir <- fs::dir_create("data")

save_parquet <- function(file) {
  path <- fs::path_ext_remove(file) |> fs::path_ext_set("parquet") |>
    fs::path_file()
  df   <- vroom::vroom(file, comment = "#", delim = ",", )
  arrow::write_parquet(df, fs::path(outdir, path))
}


fs::dir_ls(outdir) |> fs::file_delete()
zips <- list.files(path = "download", pattern = "*.zip", full.names = TRUE)
ldply(.data = zips, .fun = unzip, exdir = "data", junkpath = TRUE)

df <- list.files(path = "data", full.names = TRUE) %>%
  lapply(read_csv) %>%
  bind_rows

fs::dir_ls("data", regexp = "(*.gz)?$") |> walk(save_parquet)
