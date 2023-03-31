# Generate a cache/compound/check_ftp.txt to check for updates
out="cache/compound/sdf/check_ftp.txt" 
mkdir -p cache/compound/sdf 
wget https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/ \
  -O $out