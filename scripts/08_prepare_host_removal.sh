
#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
TRIMMED_DIR="$PROJECT_DIR/cleaned_reads/trimmed"
LOG="$PROJECT_DIR/logs/08_prepare_host_removal.log"

R1="$TRIMMED_DIR/ERR14836067_dedup_R1_unpaired_1.fq.gz"
R2="$TRIMMED_DIR/ERR14836067_dedup_R2_unpaired_2.fq.gz"
OUTPUT="$TRIMMED_DIR/ERR14836067_unpaired_combined.fq.gz"

mkdir -p "$PROJECT_DIR/logs"
exec > >(tee -a "$LOG") 2>&1

echo "=== Preparing unpaired reads ==="

# Check input files and their gzip integrity.
for f in "$R1" "$R2"; do
    [[ -s "$f" ]] || { echo "ERROR: Missing or empty file: $f"; exit 1; }
    gzip -t "$f"
    echo "PASS: $f"
done

# Do not overwrite an existing result.
if [[ -e "$OUTPUT" ]]; then
    echo "ERROR: Output already exists: $OUTPUT"
    echo "Check the existing file before running again."
    exit 1
fi

TEMP="${OUTPUT}.tmp"
trap 'rm -f "$TEMP"' EXIT

# Combine the FASTQ records and compress the result.
zcat "$R1" "$R2" | gzip -c > "$TEMP"
gzip -t "$TEMP"
mv "$TEMP" "$OUTPUT"
trap - EXIT

# Count reads: each FASTQ read has four lines.
count_reads() {
    gzip -cd "$1" | awk '
        END {
            if (NR % 4 != 0) {
                print "ERROR: Invalid FASTQ line count" > "/dev/stderr"
                exit 1
            }
            printf "%.0f", NR / 4
        }'
}

N1=$(count_reads "$R1")
N2=$(count_reads "$R2")
NOUT=$(count_reads "$OUTPUT")
EXPECTED=$((N1 + N2))

echo "Unpaired R1: $N1 reads"
echo "Unpaired R2: $N2 reads"
echo "Combined:    $NOUT reads"

[[ "$NOUT" -eq "$EXPECTED" ]] || {
    echo "ERROR: Read counts do not match."
    exit 1
}

echo "SUCCESS: Combined file verified."
echo "Output: $OUTPUT"

