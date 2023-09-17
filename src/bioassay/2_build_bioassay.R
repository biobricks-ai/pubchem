# Extract every downloaded bioassay csv.gz into parquet tables. 
# parsing done w/ respect to README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
pacman::p_load(future, furrr)
future::plan(future::multicore(workers=30))

# SETUP ======================================================================================
stgdir <- fs::dir_create("staging/bioassay")
withr::defer({ fs::dir_delete(stgdir)})

# UNZIP ALL FILES TO STGDIR ==================================================================
csvs <- fs::dir_ls("download/bioassay/csv",glob="*.zip") |> purrr::map(~ unzip(.,exdir=stgdir), .progress=TRUE) |> unlist()
aids <- as.numeric(gsub(".*/([0-9]+)\\.concise\\.csv\\.gz$", "\\1", csvs))

# CREATE STGDIR/parquet/* parquet files ======================================================
header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID","PUBCHEM_EXT_DATASOURCE_SMILES","PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL")
header_row_valu <- c("RESULT_TYPE","RESULT_DESCR","RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION","RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER","RESULT_ATTR_CONC_MICROMOL")

parqdir <- fs::dir_create(fs::path(stgdir,"parquet"))
parse_and_write_parquet <- purrr::possibly(function(csv, aid){
  
  toplines <- readLines(csv,n=20)
  headcols <- strsplit(toplines[1],",")[[1]]
  isheader <- strsplit(toplines[-1],",") |> purrr::map_lgl(~ .[1] %in% header_row_valu)
  isheader <- max(which(isheader)) + 1 
  
  df <- data.table::fread(csv, check.names=TRUE,header=FALSE,sep=",",skip=isheader)
  colnames(df) <- headcols

  # add AID and reorder cols
  natcols <- colnames(df)
  df$aid <- aid
  data.table::setcolorder(df,c("aid",natcols))
  colnames(df) <- tolower(colnames(df))

  # pivot longer on everything but aid,result_tag,sid,cid,smiles 
  df <- df |> tidyr::pivot_longer(
    cols=all_of(colnames(df)[-1:-5]),
    names_to="property", values_to="value",
    values_transform = as.character)
      
  df |> dplyr::filter(!is.na(value)) |> arrow::write_parquet(path)
  arrow::write_parquet(df, fs::path(parqdir,sprintf("%s.parquet",aid)))

}, otherwise=NULL)

furrr::future_walk2(csvs, aids, parse_and_write_parquet, .progress=TRUE)

# REPARTITION PARQUET FILES INTO brick/bioassay_concise.parquet OUTPUT =======================
brickdir <- fs::dir_create("brick/bioassay_concise.parquet")
fs::dir_ls(brickdir) |> fs::file_delete()
arrow::open_dataset(parqdir) |> arrow::write_dataset(brickdir, max_rows_per_file=1e7)