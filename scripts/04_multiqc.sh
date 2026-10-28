
#!/usr/bin/env bash
set -euo pipefail

# Step 04: Generate a combined MultiQC report

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
cd "$PROJECT_DIR"

mkdir -p qc/multiqc_report logs

multiqc qc/raw_fastqc qc/trimmed_fastqc \
    -o qc/multiqc_report \
    2>&1 | tee logs/04_multiqc.log

