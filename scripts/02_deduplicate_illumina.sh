
#!/usr/bin/env bash
set -euo pipefail

# Project paths
PROJECT="/mnt/d/Metagenomics/D02_T2_pilot"
READ1="/mnt/d/Metagenomics/ERR14836067_1.fastq.gz"
READ2="/mnt/d/Metagenomics/ERR14836067_2.fastq.gz"
SUPERDEDUPER="${PROJECT}/scripts/hts_SuperDeduper"
OUTDIR="${PROJECT}/cleaned_reads/deduplicated"
LOGDIR="${PROJECT}/logs"

# Check inputs and prepare folders
[[ -f "$READ1" ]] || { echo "ERROR: R1 not found: $READ1"; exit 1; }
[[ -f "$READ2" ]] || { echo "ERROR: R2 not found: $READ2"; exit 1; }
[[ -x "$SUPERDEDUPER" ]] || { echo "ERROR: SuperDeduper not executable"; exit 1; }

mkdir -p "$OUTDIR" "$LOGDIR"
cd "$OUTDIR"

# Save terminal output to a log
exec > >(tee -a "${LOGDIR}/02_deduplication.log") 2>&1

echo "Started: $(date)"
echo "SuperDeduper version:"
"$SUPERDEDUPER" --version

echo "Running paired-end deduplication..."
"$SUPERDEDUPER" -1 "$READ1" -2 "$READ2" \
  -f ERR14836067_dedup -L stats.log

echo "Deduplication finished."
echo "Output files:"
ls -lh "$OUTDIR"
echo "Finished: $(date)"

