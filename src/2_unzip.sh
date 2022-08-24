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

cat $temppath/files.txt | xargs -P14 -n1 bash -c '
if test -f '$rawpath'$1.sdf; then
  echo "unzip: file '$rawpath'$1.sdf already unzipped."
else
  gunzip -c -v '$downloadpath'$1.sdf.gz > '$rawpath'$1.sdf; 
fi' {}

