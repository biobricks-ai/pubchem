#!/usr/bin/env bash
wdpath=$(pwd)
dlpath="$wdpath/download/rdf/"
ftpurl="ftp://ftp.ncbi.nlm.nih.gov/pubchem/RDF/"

mkdir -p $dlpath
wget -m -nH -np --cut-dirs=4 --accept=*.ttl.gz $ftpurl -P $dlpath