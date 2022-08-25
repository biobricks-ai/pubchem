#!/usr/bin/env bash

localpath=$(pwd)
echo "Local path: $localpath"

downloadpath="$localpath/download/compound"
echo "Download path: $downloadpath"

temppath="$localpath/temp"
echo "Temporal path: $temppath"

rawpath="$localpath/raw/compound"
echo "Raw path: $rawpath"

datapath="$localpath/data/compound.parquet"
mkdir -p $datapath
echo "Data path: $datapath"

cd $datapath
xargs mkdir -p < $temppath/dirs.txt
cd $localpath

cat $temppath/files.txt | xargs -P1 -n1 bash -c '
if test -f '$datapath'$1.parquet; then
  echo "build_parquet: file '$datapath'$1.parquet already created."
else
fi' {}
