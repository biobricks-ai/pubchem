library(rvest)
library(purrr)
library(parapurrr)
library(fs)

options(timeout = 36000) # download timeout

print("Downloading Files")

pc  <- "https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/"
href <- read_html(pc) |> html_elements("a") |> html_attr("href")
tbls <- keep(href, ~ grepl("(*.gz)$", .))

urls <- path(pc, tbls)
outs <- fs::dir_create("download")
files <- fs::path(outs, fs::path_file(tbls))

start_time <- Sys.time()
print(start_time)
walk2(urls, files, download.file)
stop_time <- Sys.time()
print(stop_time)
print(stop_time - start_time)
