import re, requests, pandas as pd, time
import os, glob, json
import pyarrow as pa, pyarrow.parquet as pq
from urllib.parse import quote
from tqdm import tqdm

df = pd.read_csv('downloads/hazard_compounds.csv')
cids = df['cid'].tolist()
os.makedirs('cache/pc_compounds_json')
for cid in tqdm(cids):
    url = f"https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/{cid}/JSON"
    jso = requests.get(url).json()
    pth = f'cache/pc_compounds_json/{cid}.json'
    with open(pth, 'w') as f:
        json.dump(jso, f)
    time.sleep(0.2)

# WRITE TO PARQUET
paths = glob.glob('cache/pc_compounds_json/*.json')
padf = pd.DataFrame(columns=['cid','json_annotations'])
for path in tqdm(paths):
    jdat = open(path, 'r').read()
    pcid = int(path.split('/')[-1].split('.')[0])
    padf = padf._append({'cid':pcid,'json_annotations':jdat}, ignore_index=True)

table = pa.Table.from_pandas(padf)
pq.write_table(table, 'brick/cid_annotations.parquet')