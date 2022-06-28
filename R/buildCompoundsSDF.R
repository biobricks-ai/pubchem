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
library(cinf)

print("Reading SDF files from /raw")

deps <- dir_ls("raw")
out <- dir_create("data")

mdb <- read_sdf(deps[1], coord = FALSE)
props <- mdb_get_prop_names(mdb)
props <- props[props != ""]
df <- get_props(mdb, props)

deps <- deps[-1]

for (file in deps) {
  print(file)
  start_time <- Sys.time()
  mdb <- read_sdf(file, coord = FALSE)
  dft <- get_props(mdb, props)
  df <- bind_rows(df, dft)
  stop_time <- Sys.time()
  print(stop_time - start_time)
}

print("Writing parquet file to /data")
write_parquet(df, "data/Compunds.parquet")