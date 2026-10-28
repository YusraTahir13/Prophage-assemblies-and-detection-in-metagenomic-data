
#!/usr/bin/env bash
set -Eeuo pipefail

# 1. Project paths and resource settings
PROJECT_DIR="/mnt/d/Metagenomics/D02_T2_pilot"
TRIMMED_DIR="$PROJECT_DIR/cleaned_reads/trimmed"
REF="$PROJECT_DIR/references/hg38/hg38.fa"
OUTDIR="$PROJECT_DIR/results/host_removal"
LOGDIR="$PROJECT_DIR/logs"
LOG="$LOGDIR/09_remove_human_reads.log"

SAMPLE="ERR14836067"
THREADS=2
SAMTOOLS_THREADS=1

# 2. Input files
R1="$TRIMMED_DIR/${SAMPLE}_dedup_R1_val_1.fq.gz"
R2="$TRIMMED_DIR/${SAMPLE}_dedup_R2_val_2.fq.gz"
UNPAIRED="$TRIMMED_DIR/${SAMPLE}_unpaired_combined.fq.gz"

# 3. Final output files
OUT_R1="$OUTDIR/${SAMPLE}_cleaned_1.fastq.gz"
OUT_R2="$OUTDIR/${SAMPLE}_cleaned_2.fastq.gz"
PAIRED_SINGLETONS="$OUTDIR/${SAMPLE}_paired_singletons.fastq.gz"
UNPAIRED_UNMAPPED="$OUTDIR/${SAMPLE}_unpaired_unmapped.fastq.gz"
FINAL_ORPHANS="$OUTDIR/${SAMPLE}_cleaned_orphans.fastq.gz"
REPORT="$OUTDIR/${SAMPLE}_read_count_summary.tsv"

mkdir -p "$OUTDIR" "$LOGDIR"
exec > >(tee -a "$LOG") 2>&1

echo "=== Human-read removal ==="
date
echo "Sample: $SAMPLE"
echo "BWA threads: $THREADS"
echo "SAMtools additional threads: $SAMTOOLS_THREADS"

# 4. Check required software and inputs
command -v bwa >/dev/null
command -v samtools >/dev/null
command -v gzip >/dev/null
command -v awk >/dev/null

echo "BWA version:"
bwa 2>&1 | head -n 3 || true

echo "SAMtools version:"
samtools --version | head -n 2

for f in "$R1" "$R2" "$UNPAIRED" "$REF"; do
    [[ -s "$f" ]] || {
        echo "ERROR: Missing or empty input: $f"
        exit 1
    }
done

for suffix in amb ann bwt pac sa; do
    [[ -s "${REF}.${suffix}" ]] || {
        echo "ERROR: Missing BWA index: ${REF}.${suffix}"
        exit 1
    }
done

echo "Checking input compression..."
gzip -t "$R1"
gzip -t "$R2"
gzip -t "$UNPAIRED"

# 5. Count FASTQ records
count_reads() {
    gzip -cd "$1" | awk '
        END {
            if (NR % 4 != 0) {
                print "ERROR: FASTQ line count is not divisible by 4" > "/dev/stderr"
                exit 1
            }
            printf "%.0f", NR / 4
        }'
}

N_R1=$(count_reads "$R1")
N_R2=$(count_reads "$R2")
N_UNPAIRED=$(count_reads "$UNPAIRED")

[[ "$N_R1" -eq "$N_R2" ]] || {
    echo "ERROR: Input R1 and R2 record counts differ."
    exit 1
}

TOTAL_INPUT=$((N_R1 + N_R2 + N_UNPAIRED))

echo "Input R1 records: $N_R1"
echo "Input R2 records: $N_R2"
echo "Input unpaired records: $N_UNPAIRED"
echo "Total input read records: $TOTAL_INPUT"

# 6. Protect existing final results
for f in "$OUT_R1" "$OUT_R2" "$PAIRED_SINGLETONS" \
         "$UNPAIRED_UNMAPPED" "$FINAL_ORPHANS" "$REPORT"; do
    [[ ! -e "$f" ]] || {
        echo "ERROR: Output already exists: $f"
        echo "Inspect previous results before retrying."
        exit 1
    }
done

# 7. Temporary working directory
TMPDIR_RUN=$(mktemp -d "$OUTDIR/.${SAMPLE}.tmp.XXXXXX")
trap 'rm -rf "$TMPDIR_RUN"' EXIT

TMP_PAIRED_BAM="$TMPDIR_RUN/paired_alignment.bam"
TMP_UNPAIRED_BAM="$TMPDIR_RUN/unpaired_alignment.bam"

TMP_R1="$TMPDIR_RUN/cleaned_1.fastq.gz"
TMP_R2="$TMPDIR_RUN/cleaned_2.fastq.gz"
TMP_SINGLETONS="$TMPDIR_RUN/paired_singletons.fastq.gz"
TMP_UNPAIRED_OUT="$TMPDIR_RUN/unpaired_unmapped.fastq.gz"
TMP_ORPHANS="$TMPDIR_RUN/cleaned_orphans.fastq.gz"
TMP_REPORT="$TMPDIR_RUN/read_count_summary.tsv"

# 8. Align paired-end reads to human reference
echo "Step 1: Aligning paired-end reads to hg38..."

bwa mem -t "$THREADS" "$REF" "$R1" "$R2" \
    2> "$OUTDIR/${SAMPLE}_paired_bwa.log" \
    | samtools view -@ "$SAMTOOLS_THREADS" -b \
        -o "$TMP_PAIRED_BAM" -

# Count primary mapped read records.
# 0x904 excludes unmapped, secondary and supplementary records.
MAPPED_PAIRED=$(samtools view -c -F 0x904 "$TMP_PAIRED_BAM")

# Keep only unmapped records.
# -1/-2 retain complete unmapped pairs; -s collects singletons.
samtools fastq -@ "$SAMTOOLS_THREADS" -f 4 \
    -1 "$TMP_R1" \
    -2 "$TMP_R2" \
    -s "$TMP_SINGLETONS" \
    -0 /dev/null \
    "$TMP_PAIRED_BAM"

# 9. Align originally unpaired reads separately
echo "Step 2: Aligning originally unpaired reads to hg38..."

bwa mem -t "$THREADS" "$REF" "$UNPAIRED" \
    2> "$OUTDIR/${SAMPLE}_unpaired_bwa.log" \
    | samtools view -@ "$SAMTOOLS_THREADS" -b \
        -o "$TMP_UNPAIRED_BAM" -

MAPPED_UNPAIRED=$(samtools view -c -F 0x904 "$TMP_UNPAIRED_BAM")

samtools fastq -@ "$SAMTOOLS_THREADS" -f 4 "$TMP_UNPAIRED_BAM" \
    | gzip -c > "$TMP_UNPAIRED_OUT"

# 10. Combine retained singleton and originally unpaired reads
echo "Step 3: Combining retained orphan reads..."

zcat "$TMP_SINGLETONS" "$TMP_UNPAIRED_OUT" \
    | gzip -c > "$TMP_ORPHANS"

# 11. Validate compressed output files
for f in "$TMP_R1" "$TMP_R2" "$TMP_SINGLETONS" \
         "$TMP_UNPAIRED_OUT" "$TMP_ORPHANS"; do
    gzip -t "$f"
done

# 12. Count retained records
N_OUT_R1=$(count_reads "$TMP_R1")
N_OUT_R2=$(count_reads "$TMP_R2")
N_SINGLETONS=$(count_reads "$TMP_SINGLETONS")
N_UNPAIRED_OUT=$(count_reads "$TMP_UNPAIRED_OUT")
N_ORPHANS=$(count_reads "$TMP_ORPHANS")

[[ "$N_OUT_R1" -eq "$N_OUT_R2" ]] || {
    echo "ERROR: Retained R1 and R2 counts differ."
    exit 1
}

[[ "$N_ORPHANS" -eq "$((N_SINGLETONS + N_UNPAIRED_OUT))" ]] || {
    echo "ERROR: Combined orphan count does not match its components."
    exit 1
}

MAPPED_TOTAL=$((MAPPED_PAIRED + MAPPED_UNPAIRED))

# Count each retained record exactly once:
# paired R1 + paired R2 + combined orphan records.
TOTAL_RETAINED=$((N_OUT_R1 + N_OUT_R2 + N_ORPHANS))

# Confirm input records are accounted for.
if [[ $((MAPPED_TOTAL + TOTAL_RETAINED)) -ne "$TOTAL_INPUT" ]]; then
    echo "ERROR: Input, mapped and retained record counts do not balance."
    echo "Input records: $TOTAL_INPUT"
    echo "Mapped primary records: $MAPPED_TOTAL"
    echo "Retained records: $TOTAL_RETAINED"
    echo "No final outputs will be published."
    exit 1
fi

# 13. Generate the read-count report
{
    printf "metric\tread_records\tpercent_of_input\n"

    awk -v n="$N_R1" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "input_R1\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_R2" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "input_R2\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_UNPAIRED" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "input_unpaired\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$TOTAL_INPUT" \
        'BEGIN { printf "total_input_read_records\t%.0f\t100.0000%%\n", n }'

    awk -v n="$MAPPED_PAIRED" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "mapped_paired_primary_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$MAPPED_UNPAIRED" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "mapped_unpaired_primary_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$MAPPED_TOTAL" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "total_mapped_primary_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_OUT_R1" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "retained_paired_R1_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_OUT_R2" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "retained_paired_R2_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_SINGLETONS" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "retained_paired_singletons\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_UNPAIRED_OUT" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "retained_originally_unpaired_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$N_ORPHANS" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "total_retained_orphan_records\t%.0f\t%.4f%%\n", n, 100*n/t }'

    awk -v n="$TOTAL_RETAINED" -v t="$TOTAL_INPUT" \
        'BEGIN { printf "total_retained_read_records\t%.0f\t%.4f%%\n", n, 100*n/t }'
} > "$TMP_REPORT"

# 14. Publish results only after validation succeeds
mv "$TMP_R1" "$OUT_R1"
mv "$TMP_R2" "$OUT_R2"
mv "$TMP_SINGLETONS" "$PAIRED_SINGLETONS"
mv "$TMP_UNPAIRED_OUT" "$UNPAIRED_UNMAPPED"
mv "$TMP_ORPHANS" "$FINAL_ORPHANS"
mv "$TMP_REPORT" "$REPORT"

echo "=== Human-read removal completed successfully ==="
echo "Mapped primary read records: $MAPPED_TOTAL"
echo "Retained read records: $TOTAL_RETAINED"
echo "Read-count report: $REPORT"
echo "BWA paired log: $OUTDIR/${SAMPLE}_paired_bwa.log"
echo "BWA unpaired log: $OUTDIR/${SAMPLE}_unpaired_bwa.log"
echo "Main log: $LOG"

