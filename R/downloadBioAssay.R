library(rvest)
library(purrr)
library(parapurrr)
library(fs)

options(timeout = 3600) # download timeout

print("Downloading Files")

pc  <- "https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/"
href <- read_html(pc) |> html_elements("a") |> html_attr("href")
tbls <- keep(href, ~ grepl("(*.zip)$", .))

# To change later to full download remove and replace tbls10 by tbls
tblssm <- (tbls)[3:5]

urls <- path(pc, tblssm)
outs <- fs::dir_create("download")
files <- fs::path(outs, fs::path_file(tblssm))
walk2(urls, files, download.file)
