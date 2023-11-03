# Generate a cache/compound/check_ftp.txt to check for updates
out="cache/bioassay/extras/check_ftp.txt" 
mkdir -p cache/bioassay/extras
wget https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/Extras/ -O $out