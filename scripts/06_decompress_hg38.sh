#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_Pilot"
REF_DIR="$PROJECT_DIR/references/hg38"
LOG_FILE="$PROJECT_DIR/logs/06_decompress_hg38.log"

mkdir -p "$PROJECT_DIR/logs"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "Step 06: Decompress hg38 reference genome"
echo "Started at: $(date)"
echo "========================================"

cd "$REF_DIR"

if [[ ! -s "hg38.fa.gz" ]]; then
    echo "ERROR: hg38.fa.gz is missing or empty."
    exit 1
fi

if [[ -s "hg38.fa" ]]; then
    echo "ERROR: hg38.fa already exists. Stopping to avoid overwriting."
    exit 1
fi

gzip -t hg38.fa.gz
gzip -dc hg38.fa.gz > hg38.fa

echo "Decompression completed at: $(date)"
ls -lh hg38.fa

echo "Step 06 completed successfully."
