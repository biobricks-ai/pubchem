# Extract every downloaded bioassay csv.gz into parquet tables. 
# README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
# parsing done with respect to README.
library(dplyr)

outdir <- fs::dir_create("brick/bioassay/csv.parquet")
stgdir <- tempdir()

process_zip <- function(F){
  td <- tempdir()
  unzip(F,exdir=td)
  fs::dir_ls(td,recurse=TRUE,glob="*.csv.gz")
}

required_header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID",
"PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL",
"PUBCHEM_ASSAYDATA_COMMENT")

header_row_indicator <- c("RESULT_TYPE","RESULT_DESCR",
"RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION",
"RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER",
"RESULT_ATTR_CONC_MICROMOL")

allcols <- c()
stage_parquet = function(csvgz){
  # read csv.gz file
  df <- readr::read_csv(csvgz, col_types = readr::cols())
  
  # remove extra header rows
  rtag <- df$PUBCHEM_RESULT_TAG
  last_hrow <- rtag |> purrr::detect_index(~ !(. %in% header_row_indicator))
  df <- df[last_hrow:nrow(df),]

  # mutate all non-required headers to character type
  df <- df |> mutate(across(!one_of(required_header), as.character))

  # update allcols
  allcols <<- c(allcols, colnames(df)) |> unique()

  # write to staging directory
  ppath <- stgdir |> fs::path(uuid::UUIDgenerate(),ext="parquet")
  arrow::write_parquet(df, ppath)
  ppath
}

# TODO replace files rather than deleting everything
fs::dir_ls(outdir) |> fs::file_delete()

zipfl <- fs::dir_ls("download/bioassay/csv/",glob="*.zip")
csvgz <- zipfl |> purrr::map(process_zip,.progress=TRUE) |> purrr::flatten_chr()
staged_parquet <- csvgz |> purrr::map_chr(stage_parquet,.progress=TRUE)

# CREATE OUTPUT PARQUET DIRECTORY ============================================================
# read the staged parquet files, add missing columns, add to bigDF, write 1e7 sized chunks 
bigDF <- arrow::read_parquet(staged_parquet[1]) |> collect() 

# add missing columns to bigdf
missing_cols <- setdiff(allcols, names(df))
newcols <- data.frame(matrix(NA_character_, nrow = nrow(bigdf), ncol = length(missing_cols)))
colnames(newcols) <- missing_cols
bigDF <- bigDF |> bind_cols(newcols)

for(i in 2:length(staged_parquet)){
  df <- arrow::read_parquet(staged_parquet[i]) |> collect()
  bigDF <- dplyr::bind_rows(bigDF,df)
  while(nrow(bigDF) > 1e7){
    outDF <- bigDF[1:1e7,]
    bigDF <- bigDF[-(1:1e7),]
    arrow::write_parquet(outDF, outname)
  }
}