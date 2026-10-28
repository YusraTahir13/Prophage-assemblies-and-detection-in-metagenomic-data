#!/usr/bin/env bash
set -Eeuo pipefail

# Run from the project root directory.
ROOT="/mnt/d/Metagenomics/D02_T2_pilot"
cd "$ROOT"

SAMPLE="ERR14836067"
REF="references/hg38/hg38.fa"
R1="cleaned_reads/trimmed/${SAMPLE}_dedup_R1_val_1.fq.gz"
R2="cleaned_reads/trimmed/${SAMPLE}_dedup_R2_val_2.fq.gz"
MM2="$HOME/minimap2-v2.26/minimap2"
OUT="results/crosscheck_2000"

mkdir -p "$OUT"

# Check required tools and input files.
for tool in bwa samtools zcat awk; do
    command -v "$tool" >/dev/null || {
        echo "ERROR: $tool not found."
        exit 1
    }
done

[[ -x "$MM2" ]] || {
    echo "ERROR: Minimap2 executable not found at $MM2"
    exit 1
}

[[ -s "$REF" && -s "$R1" && -s "$R2" ]] || {
    echo "ERROR: Reference or input FASTQ file is missing/empty."
    exit 1
}

# Do not overwrite any earlier cross-check outputs.
if [[ -e "$OUT/test_R1.fastq" || -e "$OUT/test_R2.fastq" ||
      -e "$OUT/bwa.bam" || -e "$OUT/minimap2.bam" ]]; then
    echo "ERROR: Cross-check output files already exist in $OUT."
    echo "To protect previous results, nothing was overwritten."
    echo "Choose a new output folder or inspect the existing files first."
    exit 1
fi

echo "Creating a test sample of 2,000 paired reads..."
zcat "$R1" | awk 'NR <= 8000' > "$OUT/test_R1.fastq"
zcat "$R2" | awk 'NR <= 8000' > "$OUT/test_R2.fastq"

N1=$(awk 'END {print NR/4}' "$OUT/test_R1.fastq")
N2=$(awk 'END {print NR/4}' "$OUT/test_R2.fastq")

if [[ "$N1" -ne 2000 || "$N2" -ne 2000 ]]; then
    echo "ERROR: Expected 2,000 reads in each mate; found R1=$N1, R2=$N2."
    exit 1
fi

echo "Sample verified: R1=$N1; R2=$N2"
echo "Running BWA..."
bwa mem -t 2 "$REF" "$OUT/test_R1.fastq" "$OUT/test_R2.fastq" \
    2> "$OUT/bwa.log" \
    | samtools view -b -o "$OUT/bwa.bam" -

samtools flagstat "$OUT/bwa.bam" > "$OUT/bwa_flagstat.txt"

echo "Running Minimap2..."
"$MM2" -ax sr -t 2 "$REF" "$OUT/test_R1.fastq" "$OUT/test_R2.fastq" \
    2> "$OUT/minimap2.log" \
    | samtools view -b -o "$OUT/minimap2.bam" -

samtools flagstat "$OUT/minimap2.bam" > "$OUT/minimap2_flagstat.txt"

# Summarize the number of mapped primary alignment records.
BWA_MAPPED=$(samtools view -c -F 0x904 "$OUT/bwa.bam")
MM2_MAPPED=$(samtools view -c -F 0x904 "$OUT/minimap2.bam")

{
    printf "tool\tmapped_primary_records\n"
    printf "BWA\t%s\n" "$BWA_MAPPED"
    printf "Minimap2\t%s\n" "$MM2_MAPPED"
} > "$OUT/crosscheck_summary.tsv"

echo
echo "Cross-check complete."
echo "BWA mapped primary records: $BWA_MAPPED"
echo "Minimap2 mapped primary records: $MM2_MAPPED"
echo "Results saved in: $OUT"
echo "Detailed statistics: $OUT/bwa_flagstat.txt and $OUT/minimap2_flagstat.txt"
echo "Summary table: $OUT/crosscheck_summary.tsv"
