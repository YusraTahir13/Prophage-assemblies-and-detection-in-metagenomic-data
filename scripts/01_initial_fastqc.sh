#!/usr/bin/env bash

set -euo pipefail

READ1="/mnt/d/Metagenomics/ERR14836067_1.fastq.gz"
READ2="/mnt/d/Metagenomics/ERR14836067_2.fastq.gz"

OUTDIR="qc/raw_fastqc"

mkdir -p "${OUTDIR}"

fastqc \
    -o "${OUTDIR}" \
    -f fastq \
    -q \
    "${READ1}" \
    "${READ2}" \
    -t 2
