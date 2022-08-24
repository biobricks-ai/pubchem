#!/usr/bin/env bash

# Download files

localpath=$(pwd)
echo "Local path: $localpath"

downloadpath="$localpath/download/compound"
echo "Download path: $downloadpath"
mkdir -p "$downloadpath"
cd $downloadpath;
ftpbase="ftp://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/"
wget -r -A sdf.gz -nH --cut-dirs=4 -nc $ftpbase
echo "Download done."
