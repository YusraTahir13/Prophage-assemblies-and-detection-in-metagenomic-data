# Metagenomic Workflow Reproduction: Prophage Detection and Host Assignment

## 1. Project Overview

This repository documents a reproduction of the computational workflow described in the research paper [“Long-read metagenomics reveals phage dynamics in the human gut microbiome”](https://www.nature.com/articles/s41586-025-09786-2) upto 'Prophages in long-read assemblies'.

The project aims to establish and document a reproducible metagenomic analysis workflow, beginning with sequencing-read quality control and preprocessing and progressing towards microbial assembly, viral and prophage detection, and host assignment.

The initial analysis uses a pilot dataset (D02_T2_sample) containing paired-end short-read sequencing data and a corresponding long-read dataset. The pilot approach allows the workflow, software requirements, intermediate outputs, and potential computational issues to be assessed before extending the analysis to additional samples.

The implementation is being developed with reference to the published study, the relevant github workflow resources, and the project requirements. The workflow is executed through individual Bash scripts in a Linux environment using Windows Subsystem for Linux (WSL).

## 2. Pilot Dataset

The workflow is being performed initially using only the (D02_pilot_sample) raw dataset. Three sequencing FASTQ files were downloaded from the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home), study accession PRJEB88320. These include two paired-end short-read files (R1 and R2) and one corresponding long-read file.

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

**Input**

ERR14836067_1.fastq.gz (R1)

ERR14836067_2.fastq.gz (R2)

**Tool:** FastQC v0.12.1

**Output**

[qc/raw_fastqc/ERR14836067_1_fastqc.html](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/raw_fastqc/ERR14836067_1_fastqc.html)

[qc/raw_fastqc/ERR14836067_2_fastqc.html](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/raw_fastqc/ERR14836067_2_fastqc.html)

### ii. Deduplication 

Following the initial quality assessment, SuperDeduper was used to identify and remove duplicate paired-end fragments.

**Input**

Paired-end short reads from run ERR14836067_1.fastq.gz (R1) and ERR14836067_2.fastq.gz (R2)

**Tool:** SuperDeduper (v1.3.3)

**Output**

cleaned_reads/deduplicated/ERR14836067_dedup_R1.fastq.gz

cleaned_reads/deduplicated/ERR14836067_dedup_R2.fastq.gz

**Results**

|    Metric                           |        Count          |
|------------------------------------ |-----------------------|
| Input paired-end fragments          | 17,288,597            |
| Output paired-end fragments         | 17,288,597            |
| Duplicate fragments detected        |     0                 |
| Ignored fragments                   |     0                 |
| R1 output reads                     |  17,288,597           |
| R2 output reads                     |  17,288,597           |
| Total output reads across R1 and R2 | 34,577,194            |

No duplicate fragments were detected. The output files were verified to contain 17,288,597 reads each.

[Deduplication statistics](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/cleaned_reads/deduplicated/stats.log)

### iii. Adapter and Quality Trimming 

Trimming was configured to remove adapter sequences and low-quality bases from the paired-end reads.

**Input**

The input files were paired-end, deduplicated FASTQ files generated during the previous deduplication step.

Read 1 (R1): cleaned_reads/deduplicated/ERR14836067_dedup_R1.fastq.gz

Read 2 (R2): cleaned_reads/deduplicated/ERR14836067_dedup_R2.fastq.gz

**Tool:** Trim Galore v0.6.7

**Output**

Trimmed paired-end FASTQ files in [cleaned_reads/trimmed/](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/tree/main/cleaned_reads/trimmed)

| Output file                           | Result after trimming    |
| --------------------------------------|--------------------------|
|ERR14836067_dedup_R1_val_1.fq.gz       |17,232,868 paired R1 reads|
|ERR14836067_dedup_R2_val_2.fq.gz       |17,232,868 paired R2 reads|
|ERR14836067_dedup_R1_unpaired_1.fq.gz  |41,567 unpaired R1 reads  |
|ERR14836067_dedup_R2_unpaired_2.fq.gz  |28,578 unpaired R2 reads  |

Of 17,288,597 input read pairs, 17,232,868 pairs (99.68%) were retained after adapter and quality trimming (Q30) and the 60 bp minimum paired-read length filter. Eligible reads were saved separately as unpaired reads when their mate did not meet the paired-end length requirement. The unpaired reads had a minimum length of 35 bp.

[FastQC reports: qc/trimmed_fastqc/](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/tree/main/qc/trimmed_fastqc)

[Multiqc report after trimming](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/multiqc_report/multiqc_report.html)

### iv. Human-Read Removal

- The human reference genome was downloaded to identify and remove human-derived reads from the metagenomic sequencing data. The hg38 (GRCh38) reference genome was used for host-read removal.

**Reference source:** UCSC Genome Browse

Downloaded file: references/hg38/hg38.fa.gz

- The reference genome was downloaded in compressed .gz format.It was decompressed to obtain the plain FASTA file required for reference indexing and alignment with BWA.

**Input:** references/hg38/hg38.fa.gz

**Output:** references/hg38/hg38.fa

- After decompression, the hg38.fa file had a reported size of approximately 3.1 GB. The FASTA file contains the human genome nucleotide sequences used as the reference during read alignment.

- The reference genome file references/hg38/hg38.fa was used as the input file to perform indexing using BWA v0.7.17-r1188.

**Input File:** references/hg38/hg38.fa

**Output Files:**

- hg38.fa.amb
- hg38.fa.ann
- hg38.fa.bwt
- hg38.fa.pac
- hg38.fa.sa
  
The indexing process was completed successfully, and all five output index files were generated.

- The R1 and R2 unpaired reads were combined into a single FASTQ file so that reads originating from either input could be processed together in one BWA alignment step against the human reference genome.

**Input files:**

[cleaned_reads/trimmed/ERR14836067_dedup_R1_unpaired_1.fq.gz](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/cleaned_reads/trimmed/ERR14836067_dedup_R1_unpaired_1.fq.gz)
  
[cleaned_reads/trimmed/ERR14836067_dedup_R2_unpaired_2.fq.gz](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/cleaned_reads/trimmed/ERR14836067_dedup_R2_unpaired_2.fq.gz)
  
**Combined output:**

[cleaned_reads/trimmed/ERR14836067_unpaired_combined.fq.gz](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/cleaned_reads/trimmed/ERR14836067_unpaired_combined.fq.gz)

The combined file contained 70,145 reads, matching the sum of the two input files.

**Tools**

**BWA v0.7.17-r1188** and **SAMtools v1.16.1** were used to align paired and unpaired reads against hg38 and extract unmapped reads.

**Input files:**

cleaned_reads/trimmed/ERR14836067_dedup_R1_val_1.fq.gz
  
cleaned_reads/trimmed/ERR14836067_dedup_R2_val_2.fq.gz
  
cleaned_reads/trimmed/ERR14836067_unpaired_combined.fq.gz
  
**Reference:** references/hg38/hg38.fa

- BWA v0.7.17-r1188, using 2 threads was used to align the reads against the hg38 reference genome. SAMtools v1.16.1, using 1 additional thread was used to process alignment records and extract unmapped reads into FASTQ files.

- Paired-end reads and originally unpaired reads were processed in separate alignment steps. Retained singleton/orphan reads were tracked, and the retained orphan outputs were combined into a final orphan file.

**Output files**

ERR14836067_cleaned_1.fastq.gz

ERR14836067_cleaned_2.fastq.gz

ERR14836067_paired_singletons.fastq.gz

ERR14836067_unpaired_unmapped.fastq.gz

ERR14836067_cleaned_orphans.fastq.gz

ERR14836067_read_count_summary.tsv

**Alignment logs:**

[results/host_removal/ERR14836067_paired_bwa.log](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/results/host_removal/ERR14836067_paired_bwa.log)
  
[results/host_removal/ERR14836067_unpaired_bwa.log](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/results/host_removal/ERR14836067_unpaired_bwa.log)

### Read-Count Summary and Validation

The human-removal script reported the following counts:

| Metric                        | Read records     |
|-------------------------------|------------------|
|Input paired R1                | 17,232,868       |
|Input paired R2                | 17,232,868       |
|Input unpaired                 | 70,145           |
|Total input records            | 34,535,881       |
|Mapped primary records reported|      0           |
|Retained records reported      | 34,535,881       |

The script reported zero mapped primary records. This result must be verified before concluding that human-derived reads were successfully removed.

### v. Quality Control After Host Removal

FastQC was run on the retained reads to assess their quality after host removal.

**FastQC input files:**

- results/host_removal/ERR14836067_cleaned_1.fastq.gz
- results/host_removal/ERR14836067_cleaned_2.fastq.gz
- results/host_removal/ERR14836067_cleaned_orphans.fastq.gz

**Output:** [qc/cleaned_fastqc/](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/tree/main/qc/cleaned_fastqc)

MultiQC was used to consolidate FastQC reports from the raw, trimmed, and post-host-removal stages.

**MultiQC report:** [qc/multiqc_post_host_removal/multiqc_report.html](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/qc/multiqc_post_host_removal/multiqc_report.html)


