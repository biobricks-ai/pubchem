#!/usr/bin/env bash
# mirror https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/  
# to download directory

ftpurl="ftp.ncbi.nlm.nih.gov"
mkdir -p download/pubchem/Bioassay/Concise/CSV/Data/
lftp -c "open $ftpurl; cd pubchem/Bioassay/Concise/CSV/Data; \
mirror -e --delete ./ download/pubchem/Bioassay/Concise/CSV/Data"
