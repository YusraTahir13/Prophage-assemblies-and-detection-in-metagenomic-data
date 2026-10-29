# Metagenomic Workflow Reproduction: Prophage Detection and Host Assignment

## 1. Project Overview

This repository documents a reproduction of the computational workflow described in the research paper “Long-read metagenomics reveals phage dynamics in the human gut microbiome” upto 'Prophages in long-read assemblies' (Nature, DOI: 10.1038/s41586-025-09786-2).

The project aims to establish and document a reproducible metagenomic analysis workflow, beginning with sequencing-read quality control and preprocessing and progressing towards microbial assembly, viral and prophage detection, and host assignment.

The initial analysis uses a pilot dataset (D02_T2_sample) containing paired-end short-read sequencing data and a corresponding long-read dataset. The pilot approach allows the workflow, software requirements, intermediate outputs, and potential computational issues to be assessed before extending the analysis to additional samples.

The implementation is being developed with reference to the published study, the relevant Bhatt Lab workflow resources, and the project requirements. The workflow is executed through individual Bash scripts in a Linux environment using Windows Subsystem for Linux (WSL).

## 2. Pilot Dataset

The workflow is being performed initially using only the (D02_pilot_sample) raw dataset. Three sequencing FASTQ files were downloaded from the European Nucleotide Archive (ENA), study accession PRJEB88320. These include two paired-end short-read files (R1 and R2) and one corresponding long-read file.

| Data type     |  Run accession    |   File                 | Read_count   |
|---------------|-------------------|------------------------|--------------|
| Short-read R1 | ERR14836067       | ERR14836067_1.fastq.gz |  17288597    |
| Short-read R2 | ERR14836067       | ERR14836067_2.fastq.gz |  17288597    |
| Long read     | ERR14838507       | ERR14838507.fastq.gz   |  7294984     |

All three downloaded files passed the gzip integrity check. Because of their large size, The raw FASTQ files have not been uploaded to GitHub. The current analysis focuses on short-read preprocessing; long-read analysis will be performed separately.

## 3. Quality control and preprocessing

The initial preprocessing phase focuses on sequencing quality control and read preprocessing, following the general workflow described in the paper, include initial quality assessment, duplicate removal, adapter and quality trimming, and human-read removal. This phase prepares the short-read data for subsequent metagenomic assembly and viral/prophage detection.

### i. Initial Quality Control 

FastQC was used to assess the quality of the raw paired-end short-read data before further processing.

### Input

ERR14836067_1.fastq.gz (R1)

ERR14836067_2.fastq.gz (R2)

**Tool:** FastQC v0.12.1

### Output

[qc/raw_fastqc/ERR14836067_1_fastqc.html](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/raw_fastqc/ERR14836067_1_fastqc.html)

[qc/raw_fastqc/ERR14836067_2_fastqc.html](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/raw_fastqc/ERR14836067_2_fastqc.html)

### ii. Deduplication 

Following the initial quality assessment, SuperDeduper was used to identify and remove duplicate paired-end fragments.

### Input

Paired-end short reads from run ERR14836067_1.fastq.gz (R1) and ERR14836067_2.fastq.gz (R2)

**Tool:** SuperDeduper (v1.3.3)

### Output

cleaned_reads/deduplicated/ERR14836067_dedup_R1.fastq.gz

cleaned_reads/deduplicated/ERR14836067_dedup_R2.fastq.gz

### Results

|    Metric                           |        Count        |
|------------------------------------ |---------------------|
| Input paired-end fragments          | 17,288,597          |
| Output paired-end fragments         | 17,288,597          |
| Duplicate fragments detected        |     0               |
| Ignored fragments                   |     0               |
| R1 output reads                     |  17,288,597         |
| R2 output reads                     |  17,288,597         |
| Total output reads across R1 and R2 | 34,577,194          |

No duplicate fragments were detected. The output files were verified to contain 17,288,597 reads each.

[Deduplication statistics]

[Deduplication log]

### iii. Adapter and Quality Trimming 

Trimming was configured to remove adapter sequences and low-quality bases from the paired-end reads.

### Input

The input files were paired-end, deduplicated FASTQ files generated during the previous deduplication step.

Read 1 (R1): cleaned_reads/deduplicated/ERR14836067_dedup_R1.fastq.gz

Read 2 (R2): cleaned_reads/deduplicated/ERR14836067_dedup_R2.fastq.gz

Tool: Trim Galore v0.6.7

### Output

Trimmed paired-end FASTQ files in [cleaned_reads/trimmed/](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/tree/main/cleaned_reads/trimmed)

| Output file                           | Result after trimming    |
| --------------------------------------|--------------------------|
|ERR14836067_dedup_R1_val_1.fq.gz       |17,232,868 paired R1 reads|
|ERR14836067_dedup_R2_val_2.fq.gz       |17,232,868 paired R2 reads|
|ERR14836067_dedup_R1_unpaired_1.fq.gz  |41,567 unpaired R1 reads  |
|ERR14836067_dedup_R2_unpaired_2.fq.gz  |28,578 unpaired R2 reads  |

Of 17,288,597 input read pairs, 17,232,868 pairs (99.68%) were retained after adapter and quality trimming (Q30) and the 60 bp minimum paired-read length filter. Eligible reads were saved separately as unpaired reads when their mate did not meet the paired-end length requirement. The unpaired reads had a minimum length of 35 bp.


4. Human-Read Removal (BWA v0.7.17 and SAMtools v1.16.1)

Human-read removal is intended to reduce host contamination before downstream metagenomic analysis.

Input

Processed paired-end reads following trimming

Tools

BWA v0.7.17 for alignment against the human reference genome

SAMtools v1.16.1 for alignment-file processing

Planned output

Reads that do not map to the human reference genome (hg38/GRCh38)

Results: The software availability and reference directory have been prepared. However, completion of reference preparation, human-read removal, and the final retained-read counts has not yet been confirmed.

5. Consolidated Quality Control (MultiQC v1.35)

MultiQC was used to aggregate available FastQC reports into a single report for convenient inspection.

Input

Available FastQC reports from the preprocessing workflow

Tool: MultiQC v1.35

Output

qc/multiqc_report/multiqc_report.html

Results: MultiQC detected six FastQC reports and generated a consolidated HTML report.

View MultiQC report

View MultiQC log

Next Steps

Once trimming and human-read removal are verified, the processed short-read data can be used for downstream metagenomic assembly, genome binning, and viral/prophage identification. The long-read dataset will be analysed separately.

