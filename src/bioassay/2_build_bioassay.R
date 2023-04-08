# Extract every downloaded bioassay csv.gz into parquet tables. 
# README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
# parsing done with respect to README.
pacman::p_load(future, furrr, log4r)
future::plan(future::multicore(workers=30))

# SETUP ======================================================================================
log <- logger("DEBUG",file_appender("log.txt"))
stgdir <- fs::dir_create("staging/bioassay")

# UNZIP ALL FILES ============================================================================
zipfs <- fs::dir_ls("download/pubchem/Bioassay/Concise/CSV/Data",glob="*.zip")
csvgz <- purrr::map(zipfs, ~ unzip(.,exdir=stgdir), .progress=TRUE)

# CREATE BRICK/BIOASSAY.PARQUET ==============================================================
header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID","PUBCHEM_EXT_DATASOURCE_SMILES","PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL")
header_row_valu <- c("RESULT_TYPE","RESULT_DESCR","RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION","RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER","RESULT_ATTR_CONC_MICROMOL")

# write 10 million rows at a time to parquet
stage_parquet = function(csvs,aids,chunk=1e7){ 
  
  parse_parquet <- purrr::possibly(function(i){
    
    toplines <- readLines(csvs[i],n=20)
    headcols <- strsplit(toplines[1],",")[[1]]
    isheader <- strsplit(toplines[-1],",") |> purrr::map_lgl(~ .[1] %in% header_row_valu)
    isheader <- max(which(isheader)) + 1 
    
    df <- data.table::fread(csvs[i], check.names=TRUE,header=FALSE,sep=",",skip=isheader)
    colnames(df) <- headcols

    # add AID and reorder cols
    natcols <- colnames(df)
    df$aid <- aids[i]
    data.table::setcolorder(df,c("aid",natcols))
    colnames(df) <- tolower(colnames(df))

    # pivot longer on everything but aid,result_tag,sid,cid,smiles 
    df <- df |> tidyr::pivot_longer(
      cols=all_of(colnames(df)[-1:-5]),
      names_to="property", values_to="value",
      values_transform = as.character)
    
    df |> dplyr::filter(!is.na(value))

  }, otherwise = NULL)

  bigdf <- data.frame()
  for(i in 1:length(csvs)){

    pivdf <- parse_parquet(i)
    
    # if pivdf is null, log the csvfile that failed, but continue
    if(is.null(pivdf)){
      warn(log,sprintf("Failed to parse %s",csvs[i]))
      next()
    }

    bigdf <- data.table::rbindlist(list(bigdf, pivdf))
    while(nrow(bigdf) > 0 && (nrow(bigdf) > chunk || i == length(csvs))){
      
      wrtdf <- bigdf[1:min(nrow(bigdf),4*chunk),]

      width <- 10
      minaid <- sprintf("%0*d", width, min(wrtdf$aid))
      maxaid <- sprintf("%0*d", width, max(wrtdf$aid))
      fname <- sprintf("%s-%s.parquet",minaid,maxaid)
      
      outp <- fs::path("brick/bioassay_concise.parquet",fname)
      arrow::write_parquet(wrtdf,outp)

      bigdf <- if(nrow(bigdf) > nrow(wrtdf)){ bigdf[-(1:nrow(wrtdf)),] }else{ data.frame() }
    }
  }
}

# sort csv.gz by assay id
# chunk csv.gz files into chunks of size 1e4
csvgz <- fs::dir_ls(stgdir,recurse=T,glob="*.concise.csv.gz") 
csvid <- as.integer(gsub(".concise.csv.gz","",fs::path_file(csvgz))) 

said <- split(csvid[order(csvid)], ceiling(seq_along(csvid)/1e4))
scsv <- split(csvgz[order(csvid)], ceiling(seq_along(csvgz)/1e4))

fs::dir_create("brick/bioassay_concise.parquet")
furrr::future_walk2(scsv, said, stage_parquet, .progress=TRUE)


# SIMPLE TEST ================================================================================
df <- arrow::open_dataset("brick/bioassay_concise.parquet") |> dplyr::count(aid) |> dplyr::collect()
csvgz <- fs::dir_ls("staging/bioassay",recurse=T,glob="*.concise.csv.gz") 
csvid <- as.integer(gsub(".concise.csv.gz","",fs::path_file(csvgz))) 
missing_aid <- length(setdiff(df$aid,csvid))
if(length(missing_aid) > 0){
  warn(log,sprintf("Missing %s AIDs",paste(missing_aid,collapse=", ")))
}

# CLEAN UP ===================================================================================
fs::dir_delete("staging/bioassay")

# TIME ESTIMATE ==============================================================================
if(interactive()){
  df <- fs::dir_ls("brick/bioassay_concise.parquet") |> fs::file_info()

  mintime <- min(df$modification_time)
  maxtime <- max(df$modification_time)
  diffsec <- as.numeric(maxtime - mintime, units="hours")
  avgdur  <- diffsec/nrow(df)
  
  # calculate remaining time assuming 200 files
  eta <- avgdur * (200 - nrow(df))
  eta <- as.difftime(eta, units="hours")
  print(sprintf("~%s hours remaining",round(100*eta)/100))
  print(sprintf("%s files created",nrow(df)))
  print(sprintf("%s total hours elapsed",round(100*diffsec)/100))
}