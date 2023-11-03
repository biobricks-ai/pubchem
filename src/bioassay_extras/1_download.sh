#!/usr/bin/env bash
# mirror https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/  
# to download directory

ftpurl="ftp.ncbi.nlm.nih.gov"
mkdir -p download/bioassay/extras

# Using lftp to mirror the remote directory to the local directory.
# Files that exist locally but not on the remote will be deleted (--delete option).
lftp -c "open $ftpurl; cd pubchem/Bioassay/Extras; mirror --delete ./ download/bioassay/extras"