# Extract every downloaded SDF file into a parquet table. 
pacman::p_load(future)

future::plan(future::multicore(workers=40))

# delete existing parquet files
# TODO - only delete the outdated parquet files
outdir <- fs::dir_create("brick/compound/sdf.parquet")
fs::dir_ls(outdir) |> fs::file_delete()

write_sdfparquet <- function(file,nmax=5e7){
  
  outdir <- fs::dir_create("brick/compound/sdf.parquet")

  # delete all existing matching parquet files
  # TODO - this is not working
  # fname <- outdir |> fs::path(fs::path_file(file)) 
  # fname <- gsub(".sdf.gz","",fname)
  # match <- fs::dir_ls(outdir) |> purrr::keep(~ startsWith(.,fname))
  # fs::file_delete(match)

  # open gzfile and initiate buffer
  gzfile <- gzfile(file,"rb")
  buff <- readr::read_lines(gzfile, n_max=nmax)
  iter <- 0
  
  while(length(buff) != 0){
    
    iter <- iter + 1

    # find molecule delimiters and make molbuff split buffer
    curdeli <- c(0,grep("^\\$\\$", buff))
    curcuts <- cut(1:length(buff), curdeli)
    molbuff <- split(buff,curcuts)
    
    # update buffer by removing processed lines and reading new lines
    buff <- buff[-1:-max(curdeli)]
    buff <- c(buff, readr::read_lines(gzfile, n_max=nmax))

    # transform sdf lines into a dataframe
    proptbl <- purrr::map_dfr(molbuff, \(lines){
    
      sdf <- paste(lines,collapse="\n")
      pat <- "> <(.+?)>\n(.*?)\n\n"

      M <- stringr::str_match_all(sdf, pat)[[1]]
      P <- c(M[,2],"sdf")
      V <- c(M[,3],sdf)

      id <- lines[1] |> as.numeric()
      data.frame(id=id, property=P, value=V)
    })

    # get filename from file param
    iname <- fs::path(sprintf("%s_%s",fname,iter),ext="parquet")
    arrow::write_parquet(proptbl, outdir |> fs::path(iname))
  }

  close(gzfile)
  rm(list=ls()); gc(); 
  return(TRUE)
}

# set future global maxsize to 10GB
options(future.globals.maxSize = 1024^3 * 10)
gzfiles <- fs::dir_ls("download/ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF")
gzfiles <- gzfiles |> purrr::keep(~fs::path_ext(.) == "gz")
start <- Sys.time()

# Takes about 2 hours
futures <- gzfiles |> purrr::map(\(gzfile){
  print(Sys.time()-start)
  future::future(write_sdfparquet(gzfile))
},.progress=TRUE)

# wait for all futures to finish
futures |> purrr::walk(future::value)