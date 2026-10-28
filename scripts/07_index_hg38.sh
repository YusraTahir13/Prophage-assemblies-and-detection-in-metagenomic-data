
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
REF_DIR="$PROJECT_DIR/references/hg38"
LOG_FILE="$PROJECT_DIR/logs/07_index_hg38.log"

mkdir -p "$PROJECT_DIR/logs"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Step 07: BWA indexing for hg38"
echo "Started at: $(date)"

cd "$REF_DIR"

if [[ ! -s "hg38.fa" ]]; then
    echo "ERROR: hg38.fa is missing or empty."
    exit 1
fi

for suffix in amb ann bwt pac sa; do
    if [[ -e "hg38.fa.$suffix" ]]; then
        echo "ERROR: Index file already exists: hg38.fa.$suffix"
        echo "Check existing files before running indexing again."
        exit 1
    fi
done

echo "Reference file:"
ls -lh hg38.fa

echo "BWA version:"
bwa 2>&1 | head -n 3 || true

echo "Starting indexing at: $(date)"
bwa index hg38.fa

echo "Checking index files:"
for suffix in amb ann bwt pac sa; do
    if [[ ! -s "hg38.fa.$suffix" ]]; then
        echo "ERROR: Missing or empty index file: hg38.fa.$suffix"
        exit 1
    fi
done

ls -lh hg38.fa.amb hg38.fa.ann hg38.fa.bwt \
       hg38.fa.pac hg38.fa.sa

echo "Indexing completed at: $(date)"
echo "Step 07 completed successfully."

