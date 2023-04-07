# Extract every downloaded bioassay csv.gz into parquet tables. 
# README: https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README 
# parsing done with respect to README.
pacman::p_load(future, furrr)
future::plan(future::multicore(workers=30))

if(fs::dir_exists("staging/bioassay")){ fs::dir_delete("staging/bioassay") }
stgdir <- fs::dir_create("staging/bioassay")

# UNZIP ALL FILES ============================================================================
zipfs <- fs::dir_ls("download/pubchem/Bioassay/Concise/CSV/Data",glob="*.zip")
csvgz <- purrr::map(zipfs, ~ unzip(.,exdir=stgdir), .progress=TRUE)

# CREATE BRICK/BIOASSAY.PARQUET ==============================================================
header <- c("PUBCHEM_RESULT_TAG","PUBCHEM_SID","PUBCHEM_CID","PUBCHEM_EXT_DATASOURCE_SMILES","PUBCHEM_ACTIVITY_OUTCOME","PUBCHEM_ACTIVITY_SCORE","PUBCHEM_ACTIVITY_URL")
header_row_valu <- c("RESULT_TYPE","RESULT_DESCR","RESULT_UNIT","RESULT_IS_ACTIVE_CONCENTRATION","RESULT_IS_ACTIVE_CONCENTRATION_QUALIFIER","RESULT_ATTR_CONC_MICROMOL")

# write 10 million rows at a time to parquet
stage_parquet = function(csvs,aids,chunk=1e7){ 
  bigdf <- data.frame()
  for(i in 1:length(csvs)){
    print(sprintf("%s out of %s nr %s",i,length(csvs),nrow(bigdf)))
    
    # if there are more than 7 commas skip this file
    n1 <- readr::read_lines(csvs[i],n_max=1)
    if(length(strsplit(n1,",")[[1]]) > 7){ next() }

    df <- data.table::fread(csvs[i])
    
    # remove header rows
    isheader <- df$PUBCHEM_RESULT_TAG[1:10] %in% header_row_valu
    df <- df[-which(isheader),]

    # add AID and reorder cols
    natcols <- colnames(df)
    df$aid <- aids[i]
    data.table::setcolorder(df,c("aid",natcols))
    colnames(df) <- tolower(colnames(df))

    # pivot longer on everything but sid,cid,smiles
    pivcols <- colnames(df)[-1:-5]
    pivdf <- df |> tidyr::pivot_longer(cols=all_of(pivcols),
      names_to="property",values_to="value",
      values_transform = as.character)
        
    bigdf <- data.table::rbindlist(list(bigdf, pivdf))
    while(nrow(bigdf) > 0 && (nrow(bigdf) > chunk || i == length(csvs))){
      
      wrtdf <- bigdf[1:min(nrow(bigdf),4*chunk),]

      width <- 10
      minaid <- sprintf("%0*d", width, min(wrtdf$aid))
      maxaid <- sprintf("%0*d", width, max(wrtdf$aid))
      fname <- sprintf("%s-%s.parquet",minaid,maxaid)
      
      outp <- fs::path("brick/bioassay.parquet",fname)
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

fs::dir_create("brick/bioassay.parquet")
furrr::future_walk2(scsv, said, stage_parquet, .progress=TRUE)


# SIMPLE TEST ================================================================================
df <- arrow::open_dataset("brick/bioassay.parquet") |> dplyr::count(aid) |> dplyr::collect()
assertthat::assert_that(length(setdiff(csvid, df$aid)) == 0)

# CLEAN UP ===================================================================================
fs::dir_delete(stgdir)