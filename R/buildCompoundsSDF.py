from tkinter.tix import FileSelectBox
from rdkit.Chem import PandasTools
import pandas as pd
import pyarrow as pyarrow
import fastparquet as fastparquet
import os

files = os.listdir("./raw")
files.sort()
# print(len(files))
# print(files[100])
files = files[0:3]
# print(len(files))

filename = "raw/" + files[0]
print(filename)
DF = PandasTools.LoadSDF(filename, molColName=None)
print(len(DF))
files = files[1:]
print(len(files))

for file in files:
    filename = "raw/" + file
    print(filename)
    DFT = PandasTools.LoadSDF(filename, molColName=None)
    DF = pd.concat([DF, DFT], ignore_index=True)
    DF.info()

DF.to_parquet('data/PubChemCompounds_000_099.parquet')