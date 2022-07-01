library(fs)
library(arrow)
library(cinf)

print("Reading SDF files from /raw")

deps <- dir_ls("raw")
out <- dir_create("data")

# deps <- deps[-1]

print(deps[1])
start_time <- Sys.time()
mdb <- read_sdf(deps[1])
props <- mdb_get_prop_names(mdb)
props <- props[props != ""]
df <- get_props(mdb, props)
stop_time <- Sys.time()
print(stop_time - start_time)

deps <- deps[-1]

for (file in deps) {
  print(file)
  start_time <- Sys.time()
  result <- try(mdb <- read_sdf(file))
  if (inherits(result, "try-error")) {
    print("Error reading SDF")
    stop_time <- Sys.time()
    print(stop_time - start_time)
    next
  }
  dft <- get_props(mdb, props)
  df <- bind_rows(df, dft)
  stop_time <- Sys.time()
  print(stop_time - start_time)
}

print("Writing parquet file to /data")
write_parquet(df, "data/Compounds.parquet")


# mdb <- read_sdf(deps[1], coord = FALSE, delete_expl_hydr = FALSE)
