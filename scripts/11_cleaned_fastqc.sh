#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
SAMPLE="ERR14836067"

INPUT_DIR="$PROJECT_DIR/results/host_removal"
OUTDIR="$PROJECT_DIR/qc/cleaned_fastqc"
LOGDIR="$PROJECT_DIR/logs"
LOG="$LOGDIR/11_cleaned_fastqc.log"

mkdir -p "$OUTDIR" "$LOGDIR"
exec > >(tee -a "$LOG") 2>&1

echo "=== FastQC on cleaned reads ==="
date
fastqc --version

INPUTS=(
    "$INPUT_DIR/${SAMPLE}_cleaned_1.fastq.gz"
    "$INPUT_DIR/${SAMPLE}_cleaned_2.fastq.gz"
    "$INPUT_DIR/${SAMPLE}_cleaned_orphans.fastq.gz"
)

for f in "${INPUTS[@]}"; do
    if [[ ! -s "$f" ]]; then
        echo "ERROR: Input file missing or empty: $f"
        exit 1
    fi
done

fastqc "${INPUTS[@]}" --outdir "$OUTDIR" --threads 2

echo "=== FastQC completed ==="
echo "Reports saved in: $OUTDIR"
date
