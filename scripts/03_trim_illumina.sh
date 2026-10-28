
#!/usr/bin/env bash
set -euo pipefail

# Project paths
PROJECT="/mnt/d/Metagenomics/D02_T2_pilot"

READ1="${PROJECT}/cleaned_reads/deduplicated/ERR14836067_dedup_R1.fastq.gz"
READ2="${PROJECT}/cleaned_reads/deduplicated/ERR14836067_dedup_R2.fastq.gz"

OUTDIR="${PROJECT}/cleaned_reads/trimmed"
LOGDIR="${PROJECT}/logs"
QCDIR="${PROJECT}/qc/trimmed_fastqc"

THREADS=2
QUALITY=30
MIN_LENGTH=60

# Check input files
[[ -f "$READ1" ]] || { echo "ERROR: R1 not found: $READ1"; exit 1; }
[[ -f "$READ2" ]] || { echo "ERROR: R2 not found: $READ2"; exit 1; }

# Check required tools
for tool in trim_galore cutadapt fastqc pigz; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: Required tool not found: $tool"
        exit 1
    }
done

# Create output folders
mkdir -p "$OUTDIR" "$LOGDIR" "$QCDIR"

# Save terminal output and errors to a log
exec > >(tee -a "${LOGDIR}/03_trimming.log") 2>&1

echo "Started: $(date)"
echo "Project: $PROJECT"
echo "Input R1: $READ1"
echo "Input R2: $READ2"
echo "Quality threshold: Q${QUALITY}"
echo "Paired minimum length: ${MIN_LENGTH} bp"
echo "Threads: ${THREADS}"

# Record tool versions
echo
echo "Trim Galore version:"
trim_galore --version

echo "Cutadapt version:"
cutadapt --version

echo "FastQC version:"
fastqc --version

echo "pigz version:"
pigz --version

# Prevent accidental overwriting of existing results
if [[ -e "${OUTDIR}/ERR14836067_dedup_R1_val_1.fq.gz" ||
      -e "${OUTDIR}/ERR14836067_dedup_R2_val_2.fq.gz" ]]; then
    echo "ERROR: Trimmed output already exists."
    echo "Inspect ${OUTDIR} before deciding whether to rerun."
    exit 1
fi

# Run paired-end quality and adapter trimming
echo
echo "Running Trim Galore..."

trim_galore \
    --quality "$QUALITY" \
    --length "$MIN_LENGTH" \
    --output_dir "$OUTDIR" \
    --paired \
    --retain_unpaired \
    --cores "$THREADS" \
    "$READ1" "$READ2"

# Confirm paired outputs exist
TRIMMED_R1="${OUTDIR}/ERR14836067_dedup_R1_val_1.fq.gz"
TRIMMED_R2="${OUTDIR}/ERR14836067_dedup_R2_val_2.fq.gz"

[[ -f "$TRIMMED_R1" ]] || {
    echo "ERROR: Trimmed R1 output not found."
    exit 1
}
[[ -f "$TRIMMED_R2" ]] || {
    echo "ERROR: Trimmed R2 output not found."
    exit 1
}

# Collect outputs for post-trimming FastQC
QC_INPUTS=("$TRIMMED_R1" "$TRIMMED_R2")

for f in \
    "${OUTDIR}/ERR14836067_dedup_R1_unpaired_1.fq.gz" \
    "${OUTDIR}/ERR14836067_dedup_R2_unpaired_2.fq.gz"
do
    if [[ -f "$f" ]]; then
        QC_INPUTS+=("$f")
    fi
done

# Run FastQC on all available trimmed read files
echo
echo "Running FastQC on trimmed reads..."

fastqc \
    --threads "$THREADS" \
    --outdir "$QCDIR" \
    "${QC_INPUTS[@]}"

# Summarize generated files
echo
echo "Trimming finished successfully."
echo
echo "Trimmed output files:"
ls -lh "$OUTDIR"

echo
echo "FastQC report files:"
ls -lh "$QCDIR"

echo
echo "Finished: $(date)"

