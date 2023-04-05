# Extract every downloaded bioassay csv.gz into parquet tables. 
# README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
# parsing done with respect to README.
pacman::p_load(future, furrr)
future::plan(future::multicore(workers=30))

stgdir <- fs::dir_create("staging/bioassay")

# UNZIP ALL FILES ============================================================================
zipfs <- fs::dir_ls("download/bioassay/csv/",glob="*.zip")
furrr::future_walk(zipfs, ~ unzip(.,exdir=stgdir), .progress=TRUE)

# CREATE BRICK/BIOASSAY.PARQUET ==============================================================

required_header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID","PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL","PUBCHEM_ASSAYDATA_COMMENT")
header_row_valu <- c("RESULT_TYPE","RESULT_DESCR","RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION","RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER","RESULT_ATTR_CONC_MICROMOL")

# write 2 million rows at a time to parquet
# @param csvs list of csv.gz files
stage_parquet = function(csvs,aids,chunk=1e6){
  bigdf <- data.frame()
  for(i in 1:length(csvs)){
    print(sprintf("%s out of %s nr %s",i,length(csvs),nrow(bigdf)))
    
    # 1:7 are the pubchem required columns
    df <- data.table::fread(csvs[i])[,1:8] 
    df$aid <- as.integer(aids[i])

    # remove header rows
    isheader <- sapply(df[1:10,1], \(x){ x %in% header_row_valu})
    hrow <- which(!isheader)[1]
    df <- df[hrow:nrow(df),]
    
    bigdf <- data.table::rbindlist(list(bigdf, df))
    while(nrow(bigdf) > 0 && (nrow(bigdf) > chunk || i == length(csvs))){
      wrtdf <- bigdf[1:min(nrow(bigdf),chunk),]
      data.table::setcolorder(wrtdf,c("aid",required_header))
      
      width <- 10
      minaid <- sprintf("%0*d", width, min(wrtdf$aid))
      maxaid <- sprintf("%0*d", width, max(wrtdf$aid))
      fname <- sprintf("%s-%s.parquet",minaid,maxaid)
      outp <- fs::path("brick/bioassay.parquet",fname)
      arrow::write_parquet(wrtdf,outp)
      
      bigdf <- if(nrow(bigdf) > chunk){ bigdf[-(1:chunk),] }else{ data.frame() }
    }
  }
}

# sort csv.gz by assay id
# chunk csv.gz files into chunks of size 1e4
csvgz <- fs::dir_ls(stgdir,recurse=T,glob="*.csv.gz") 
csvid <- as.numeric(gsub(".csv.gz","",fs::path_file(csvgz))) 

said <- split(csvid[order(csvid)], ceiling(seq_along(csvid)/1e4))
scsv <- split(csvgz[order(csvid)], ceiling(seq_along(csvgz)/1e4))
fs::dir_create("brick/bioassay.parquet")
furrr::future_walk2(scsv, said, stage_parquet, .progress=TRUE)

# PROGRESS TRACKER ===========================================================================
# 304 million bioactivities today means ~300 files
if(interactive()){
  df <- fs::dir_ls("brick/bioassay.parquet") |> fs::file_info()

  mintime <- min(df$modification_time)
  maxtime <- max(df$modification_time)
  diffsec <- as.numeric(maxtime - mintime, units="hours")
  avgdur  <- diffsec/nrow(df)
  # calculate remaining time assuming 300 files
  eta <- avgdur * (300 - nrow(df))
  eta <- as.difftime(eta, units="hours")
  print(eta)
  print(nrow(df),"files created")
}

# SIMPLE TEST ================================================================================
df <- arrow::open_dataset("brick/bioassay.parquet") |> dplyr::count(aid) |> dplyr::collect()
assertthat::assert_that(length(setdiff(csvid, df$aid)) == 0)

# CLEAN UP ===================================================================================
fs::dir_delete(stgdir)