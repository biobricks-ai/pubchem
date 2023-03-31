# Generate a cache/compound/check_ftp.txt to check for updates
out="cache/rdf/check_ftp.txt" 
mkdir -p cache/rdf/ 
wget https://ftp.ncbi.nlm.nih.gov/pubchem/RDF/ -O $out