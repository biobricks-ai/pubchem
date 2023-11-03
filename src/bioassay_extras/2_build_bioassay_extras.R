

# bioassay information
bioassay_dir <- fs::dir_create("brick/bioassay_extra/bioassay.parquet")
bioassay <- readr::read_tsv('download/bioassay/extras/bioassays.tsv.gz')
bioassay |> arrow::write_dataset(bioassay_dir, max_rows_per_file=1e7)

# Bioactivity information
bioactivity_dir <- fs::dir_create("brick/bioassay_extra/bioactivity.parquet")
bioactivities <- readr::read_tsv("download/bioassay/extras/bioactivities.tsv.gz")
bioactivities |> arrow::write_dataset(bioactivity_dir, max_rows_per_file=1e7)

# sid2cidsmiles
sid2cid_dir <- fs::dir_create("brick/bioassay_extra/sid2cid.parquet")
sid2cidsmiles <- readr::read_tsv("download/bioassay/extras/Sid2CidSMILES.gz")
sid2cidsmiles |> arrow::write_dataset(sid2cid_dir, max_rows_per_file=1e7)