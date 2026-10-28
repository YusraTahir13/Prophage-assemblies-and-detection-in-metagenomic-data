#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_Pilot"
REF_DIR="$PROJECT_DIR/references/hg38"
URL="https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"

mkdir -p "$PROJECT_DIR/logs"
LOG_FILE="$PROJECT_DIR/logs/05_download_hg38.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "Step 05: Download hg38 reference genome"
echo "Started at: $(date)"
echo "Reference directory: $REF_DIR"
echo "========================================"

mkdir -p "$REF_DIR"
cd "$REF_DIR"

if [[ -s "hg38.fa" ]]; then
    echo "ERROR: hg38.fa already exists. Skipping download."
    exit 1
fi

if [[ -s "hg38.fa.gz" ]]; then
    echo "Compressed reference already exists; skipping download."
else
    wget "$URL" -O hg38.fa.gz
fi

echo "Download step completed at: $(date)"
echo "Files currently in reference directory:"
ls -lh

echo "Step 05 completed successfully."
