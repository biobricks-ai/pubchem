# Generate a cache/compound/check_ftp.txt to check for updates
out="cache/bioassay/csv/check_ftp.txt" 
mkdir -p cache/bioassay/csv 
wget https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/ -O $out