library(purrr)
library(fs)
library(arrow)
library(readr)
library(dplyr)
library(plyr)
library(XML)
library(xml2)
library(methods)
library(R.utils)

tsub <- \(p,r){partial(gsub,pattern=p,replacement=r,ignore.case=T)}
deps <- dir_ls("download")
out  <- dir_create("data")
outs <- path(out, path_file(deps)) |> tsub("\\..*", ".xml")()
# fs::dir_ls(out) |> fs::file_delete()
# walk2(deps, outs, ~ gunzip(.x, .y, remove = FALSE))

files <- list.files(path = "data", full.names = TRUE)
print(files[[1]])
df1 <- readLines(files[1], n = 1000)
df = data.frame(values = df1)
# df1 <- read_xml(files[[1]])
# df1 <- xmlToDataFrame(files[[1]])
print(df, max = 1000)






# df <- list.files(path = "data", full.names = TRUE) %>%
#   lapply(xmlToDataFrame) %>%
#   bind_rows

# df <- xmlToDataFrame()




# save_parquet <- function(file) {
#   path <- fs::path_ext_remove(file) |> fs::path_ext_set("parquet") |>
#     fs::path_file()
#   df   <- vroom::vroom(file, comment = "#", delim = ",", )
#   arrow::write_parquet(df, fs::path(outdir, path))
# }


# fs::dir_ls("data", regexp = "(*.gz)?$") |> walk(save_parquet)
