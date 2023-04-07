# Generate a cache/compound/check_ftp.txt to check for updates
out="cache/bioassay/concise/csv/check_ftp.txt" 
mkdir -p cache/bioassay/concise/csv/
wget https://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/Concise/CSV/Data/ -O $out