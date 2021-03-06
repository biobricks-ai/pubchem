# PubChem

## Description
> PubChem is a database of chemical molecules and their activities against biological assays. The system is maintained by the National Center for Biotechnology Information (NCBI), a component of the National Library of Medicine, which is part of the United States National Institutes of Health (NIH). PubChem can be accessed for free through a web user interface. Millions of compound structures and descriptive datasets can be freely downloaded via FTP. PubChem contains multiple substance descriptions and small molecules with fewer than 100 atoms and 1,000 bonds. More than 80 database vendors contribute to the growing PubChem database.

Search website
https://pubchem.ncbi.nlm.nih.gov

FTP Download
https://pubchemdocs.ncbi.nlm.nih.gov/downloads

## Usage
```{R}
biobricks::brick_install("pubchem")
biobricks::brick_pull("pubchem")
pubchem <- brick_load_arrow("pubchem")
```
