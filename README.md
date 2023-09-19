# PubChem

<a href="https://github.com/biobricks-ai/pubchem/actions"><img src="https://github.com/biobricks-ai/pubchem/actions/workflows/bricktools-check.yaml/badge.svg?branch=main"/></a>

## TODO
### Update Annotation Download
`annotations/annotations.py` currently relies on manually downloaded downloads/hazard_compound.csv, which specifies for which compounds to get pubchem annotations. This manual process involves going to https://pubchem.ncbi.nlm.nih.gov/#input_type=list&query=vvkaOxRCcf5G1HPN8bU657KMx-xTxwGEe6EayGCwCMlgqTQ&collection=compound&alias=PubChem%3A%20PubChem%20Compound%20TOC%3A%20Chemical%20Safety to get a list of all the compounds with chemical safety data. 

Instead, we should get annotations for all pubchem compounds, but I think we'll need to work with pubchem to provide that. 