#!/usr/bin/env bash
# mirror https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/  
# to download directory
wdpath=$(pwd)
dlpath="$wdpath/download/bioassay/csv/"
ftpurl="ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/"

mkdir -p $dlpath
wget -m -nH -np --cut-dirs=4 -nd --accept=*.zip $ftpurl -P $dlpath