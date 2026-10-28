#!/usr/bin/env bash
set -Eeuo pipefail

# Project paths
PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
LOGDIR="$PROJECT_DIR/logs"
LOG="$LOGDIR/12_post_host_removal_multiqc.log"

RAW_QC="$PROJECT_DIR/qc/raw_fastqc"
TRIMMED_QC="$PROJECT_DIR/qc/trimmed_fastqc"
CLEANED_QC="$PROJECT_DIR/qc/cleaned_fastqc"

OUTDIR="$PROJECT_DIR/qc/multiqc_post_host_removal"
REPORT="multiqc_report.html"

# Create log and output directories
mkdir -p "$LOGDIR" "$OUTDIR"

# Show terminal output and save it to the log
exec > >(tee -a "$LOG") 2>&1

echo "=== Post-host-removal MultiQC ==="
date
echo "Project: $PROJECT_DIR"

# Check MultiQC installation
command -v multiqc >/dev/null
multiqc --version

# Check input directories
for dir in "$RAW_QC" "$TRIMMED_QC" "$CLEANED_QC"; do
    if [[ ! -d "$dir" ]]; then
        echo "ERROR: Missing input directory: $dir"
        exit 1
    fi
done

# Combine existing FastQC reports into one MultiQC report
multiqc \
    "$RAW_QC" \
    "$TRIMMED_QC" \
    "$CLEANED_QC" \
    --force \
    --dirs \
    --dirs-depth 1 \
    --fullnames \
    --outdir "$OUTDIR" \
    --filename "$REPORT"

echo "=== MultiQC completed ==="
echo "Report: $OUTDIR/$REPORT"
echo "Log: $LOG"
date
