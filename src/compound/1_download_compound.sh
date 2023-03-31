#!/usr/bin/env bash
wdpath=$(pwd)
dlpath="$wdpath/download/compound/sdf/"
ftpurl="ftp://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/"

mkdir -p $dlpath
wget -m -nH -np --cut-dirs=4 -nd --accept=*.sdf.gz $ftpurl -P $dlpath