from rdkit.Chem import PandasTools
import pandas as pd
import pyarrow as pyarrow
import fastparquet as fastparquet
import os
import time

def FmtMem(num):
    for unit in ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB"]:
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}"
        num /= 1024.0
    return f"{num:.1f} YiB"

os.mkdir("data")
FilesTotal = os.listdir("./raw")
FilesTotal.sort()

NumFiles = len(FilesTotal)
print("Total files:", NumFiles)
NumFilesPerParquet = 40
print("Number of files per parquet:", NumFilesPerParquet)

for i in range(0, NumFiles//NumFilesPerParquet + 1):

    Files = FilesTotal[:NumFilesPerParquet]
    FilesTotal = FilesTotal[NumFilesPerParquet:]
    print("")
    print("File, Time, Molecules, Memory")
    Filename = "raw/" + Files[0]
    Tic = time.time()
    DF = PandasTools.LoadSDF(Filename, molColName=None)
    Mem = DF.memory_usage(deep=True).sum()
    Toc = time.time() - Tic
    print(Files[0], f"{Toc:.1f} s", len(DF.index), FmtMem(Mem))
    Files = Files[1:]

    for File in Files:
        Tic = time.time()
        Filename = "raw/" + File
        DFT = PandasTools.LoadSDF(Filename, molColName=None)
        DF = pd.concat([DF, DFT], ignore_index=True)
        Mem = DF.memory_usage(deep=True).sum()
        Toc = time.time() - Tic
        print(File, f"{Toc:.1f} s", len(DF.index), FmtMem(Mem))

    ParquetFile = "data/Compound_" + f"{i}" + ".parquet"
    print(ParquetFile)
    DF.to_parquet(ParquetFile)
    ParquetFile = ParquetFile + ".gzip"
    print(ParquetFile)
    DF.to_parquet(ParquetFile, compression='gzip')
