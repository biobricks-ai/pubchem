library(rvest)
library(purrr)
library(parapurrr)
library(fs)

options(timeout = 36000) # download timeout

print("Downloading Files")

pc  <- "https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/XML/"
href <- read_html(pc) |> html_elements("a") |> html_attr("href")
tbls <- keep(href, ~ grepl("(*.gz)$", .))

# To change later to full download remove and replace tbls10 by tbls
tblssm <- (tbls)[3:5]

urls <- path(pc, tblssm)
outs <- fs::dir_create("download")
files <- fs::path(outs, fs::path_file(tblssm))

start_time <- Sys.time()
print(start_time)
walk2(urls, files, download.file)
stop_time <- Sys.time()
print(stop_time)
print(stop_time - start_time)
