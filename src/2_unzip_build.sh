#!/usr/bin/env bash

localpath=$(pwd)
echo "Local path: $localpath"

downloadpath="$localpath/download/compound"
echo "Download path: $downloadpath"

temppath="$localpath/temp"
mkdir -p $temppath
echo "Temporal path: $temppath"

rawpath="$localpath/raw/compound"
mkdir -p $rawpath
echo "Raw path: $rawpath"
cd $downloadpath
find . -type d > $temppath/dirs.txt
find . -type f -name '*.sdf.gz' | cut -c 2- | sed "s/.sdf.gz//" | sort > $temppath/files.txt
cd $rawpath
xargs mkdir -p < $temppath/dirs.txt
cd $rawpath

datapath="$localpath/data/compound.parquet"
mkdir -p $datapath
echo "Data path: $datapath"
cd $datapath
xargs mkdir -p < $temppath/dirs.txt
cd $localpath

cat $temppath/files.txt | xargs -P14 -n1 bash -c '
if test -f '$rawpath'$1.sdf; then
  echo "unzip_build: file '$datapath'$1.parquet already created."
else
  gunzip -c -v '$downloadpath'$1.sdf.gz > '$rawpath'$1.sdf;
  python src/sdf2parquet.py '$rawpath'$1.sdf '$datapath'$1.parquet
  rm '$rawpath'$1.sdf
fi' {}

