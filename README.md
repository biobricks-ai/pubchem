# PubChem

<a href="https://github.com/biobricks-ai/pubchem/actions"><img src="https://github.com/biobricks-ai/pubchem/actions/workflows/bricktools-check.yaml/badge.svg?branch=main"/></a>

## Description
> PubChem is a database of chemical molecules and their activities against biological assays. The system is maintained by the National Center for Biotechnology Information (NCBI), a component of the National Library of Medicine, which is part of the United States National Institutes of Health (NIH). PubChem can be accessed for free through a web user interface. Millions of compound structures and descriptive datasets can be freely downloaded via FTP. PubChem contains multiple substance descriptions and small molecules with fewer than 100 atoms and 1,000 bonds. More than 80 database vendors contribute to the growing PubChem database.

Search website
https://pubchem.ncbi.nlm.nih.gov

FTP Download
https://ftp.ncbi.nlm.nih.gov/pubchem/

Field Descriptions
https://ftp.ncbi.nlm.nih.gov/pubchem/specifications/pubchem_sdtags.txt

## Usage
```{R}
biobricks::brick_install("pubchem")
biobricks::brick_pull("pubchem")
pubchem <- brick_load_arrow("pubchem")
```

## TODO

### Update Annotation Download
`annotations/annotations.py` currently relies on manually downloaded downloads/hazard_compound.csv, which specifies for which compounds to get pubchem annotations. This manual process involves going to https://pubchem.ncbi.nlm.nih.gov/#input_type=list&query=vvkaOxRCcf5G1HPN8bU657KMx-xTxwGEe6EayGCwCMlgqTQ&collection=compound&alias=PubChem%3A%20PubChem%20Compound%20TOC%3A%20Chemical%20Safety to get a list of all the compounds with chemical safety data. 

Instead, we should get annotations for all pubchem compounds, but I think we'll need to work with pubchem to provide that. 