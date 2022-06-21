library(rvest)
library(purrr)
library(fs)

options(timeout=1800) # download timeout

print("Downloading Files")

pc  <- "https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/"
href <- read_html(pc) |> html_elements("a") |> html_attr("href")
tbls <- keep(href,~ grepl("(*.zip)$",.))
urls    <- path(pc,tbls)
outs <- fs::dir_create("download")
files <- fs::path(outs,fs::path_file(tbls))
walk2(urls,files,download.file)
