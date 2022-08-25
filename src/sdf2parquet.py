from rdkit.Chem import PandasTools
import pandas as pd
import sys
import pyarrow as pyarrow
import fastparquet as fastparquet


InFileName = sys.argv[1]
OutFileName = sys.argv[2]

print(f"sdf2parquet: Converting file {InFileName}")
DF = PandasTools.LoadSDF(InFileName, molColName=None)
DF.to_parquet(OutFileName)
