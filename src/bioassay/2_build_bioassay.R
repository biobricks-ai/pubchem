# Extract every downloaded bioassay csv.gz into parquet tables. 
# parsing done w/ respect to README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
pacman::p_load(future, furrr, log4r)
future::plan(future::multicore(workers=30))
log <- logger("DEBUG",file_appender("logs/bioassay.log"))
if(fs::file_exists("logs/bioassay.log")){ fs::file_delete("logs/bioassay.log") }
info(log, "starting build_bioassay.R")

# SETUP ======================================================================================
stgdir <- fs::dir_create("staging/bioassay")
fs::dir_ls(stgdir) |> fs::file_delete()
withr::defer({ fs::dir_delete(stgdir) })

# UNZIP ALL FILES TO STGDIR/download =========================================================
dldir <- fs::dir_create(fs::path(stgdir,"download"))
fs::dir_ls("download/bioassay/csv",glob="*.zip") |> purrr::walk(~ unzip(.,exdir=dldir), .progress=TRUE)
csvs <- fs::dir_ls(dldir,glob="*.csv.gz",recurse=TRUE)
aids <- as.numeric(gsub(".*/([0-9]+)\\.concise\\.csv\\.gz$", "\\1", csvs))

# CREATE STGDIR/parquet/* parquet files ======================================================
header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID","PUBCHEM_EXT_DATASOURCE_SMILES","PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL")
header_row_valu <- c("RESULT_TYPE","RESULT_DESCR","RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION","RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER","RESULT_ATTR_CONC_MICROMOL")

parqdir <- fs::dir_create(fs::path(stgdir,"parquet"))
parse_and_write_parquet <- function(csv, aid){
  
  info(log, sprintf("%s to parquet", csv))

  toplines <- readLines(csv,n=20)
  headcols <- strsplit(toplines[1],",")[[1]]
  isheader <- strsplit(toplines[-1],",") |> purrr::map_lgl(~ .[1] %in% header_row_valu)
  isheader <- max(which(isheader)) + 1 
  
  # Read csv data, add AID and reorder cols
  df <- data.table::fread(csv, check.names=TRUE,header=FALSE,sep=",",skip=isheader)
  colnames(df) <- headcols
  natcols <- colnames(df)
  df$aid <- aid
  data.table::setcolorder(df,c("aid",natcols))
  colnames(df) <- tolower(colnames(df))

  # pivot longer on everything but aid,result_tag,sid,cid,smiles 
  df <- df |> 
    tidyr::pivot_longer(cols=all_of(colnames(df)[-1:-5]), names_to="property", values_to="value", values_transform=as.character) |>
    dplyr::filter(!is.na(value))

  path <- fs::path(parqdir,gsub(".concise.csv.gz$", ".parquet", fs::path_file(csv)))
  arrow::write_parquet(df, path)
}

safe_parse_and_write <- function(csv,aid){
  tryCatch({
    parse_and_write_parquet(csv,aid)
  }, error = function(e){
    warn(log, sprintf("error parsing %s: %s", csv, e$message))
  })
}

furrr::future_walk2(csvs, aids, parse_and_write_parquet, .progress=TRUE)
info(log, "finished parsing csvs")

# REPARTITION PARQUET FILES INTO brick/bioassay_concise.parquet OUTPUT =======================
info(log, "repartitioning parquet files")
brickdir <- fs::dir_create("brick/bioassay_concise.parquet")
fs::dir_ls(brickdir) |> fs::file_delete()

# There are ~300 million bioactivities on pubchem, this should generate ~30 parquet files
arrow::open_dataset(parqdir) |> arrow::write_dataset(brickdir, max_rows_per_file=1e7)
info(log, "finished repartitioning parquet files")

# SIMPLE TEST ================================================================================
aidcounts <- arrow::open_dataset(brickdir) |> count(aid) |> collect()
setdiff(aids,aidcounts$aid) |> length() 
# TODO currently 266 aids are missing. 