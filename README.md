# Metagenomic Workflow Reproduction: Prophage Detection and Host Assignment

## 1. Project Overview

This repository documents a reproduction of the computational workflow described in the research paper [“Long-read metagenomics reveals phage dynamics in the human gut microbiome”](https://www.nature.com/articles/s41586-025-09786-2) upto **'Prophages in long-read assemblies'.**

The project aims to establish and document a reproducible metagenomic analysis workflow, beginning with sequencing-read quality control and preprocessing and progressing towards microbial assembly, viral and prophage detection, and host assignment.

The initial analysis uses a pilot dataset (D02_T2_sample) containing paired-end short-read sequencing data and a corresponding long-read dataset. The pilot approach allows the workflow, software requirements, intermediate outputs, and potential computational issues to be assessed before extending the analysis to additional samples.

The implementation is being developed with reference to the published study, the relevant github workflow resources, and the project requirements. The workflow is executed through individual Bash scripts in a Linux environment using Windows Subsystem for Linux (WSL).

## 2. Pilot Dataset

The workflow is being performed initially using only the (D02_pilot_sample) raw dataset. Three sequencing FASTQ files were downloaded from the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home), study accession PRJEB88320. These include two paired-end short-read files (R1 and R2) and one corresponding long-read file.

| Data type     |  Run accession    |   File                 | Read_count   | Base_count |
|---------------|-------------------|------------------------|--------------|------------|
| Short-read R1 | ERR14836067       | ERR14836067_1.fastq.gz |  17288597    |  2.5 Gbp   |
| Short-read R2 | ERR14836067       | ERR14836067_2.fastq.gz |  17288597    |  2.5 Gbp   |
| Long read     | ERR14838507       | ERR14838507.fastq.gz   |  7294984     |  32.23 Gb  |

All three downloaded files passed the gzip integrity check. Because of their large size, The raw FASTQ files have not been uploaded to GitHub. The current analysis focuses on short-read preprocessing; long-read analysis will be performed separately.

## 3(a). Quality control and preprocessing for short reads

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

- [hg38.fa.amb](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/references/hg38/hg38.fa.amb)
- [hg38.fa.ann](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/blob/main/references/hg38/hg38.fa.ann)
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

[results/host_removal](https://github.com/YusraTahir13/Prophage-assemblies-and-detection-in-metagenomic-data/tree/main/results/host_removal)

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
|Mapped primary records reported|    0             |
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

## 3(b) Quality control and preprocessing for long reads

The initial preprocessing phase focuses on sequencing quality control and read preprocessing, following the general workflow described in the paper, include raw quality control, filtering, human-read removal and post qc. This phase prepares the long-read data for subsequent metagenomic assembly and viral/prophage detection.

### i. Raw Long-Read Quality Control (NanoPlot) 

Raw Nanopore long-read sequencing data was subjected to initial quality control (QC) using NanoPlot to assess read quality, read-length distribution, and sequencing statistics before downstream processing.

**Input file**

/mnt/d/Metagenomics/ERR14838507.fastq.gz

The input file was a compressed FASTQ file containing raw, unprocessed Nanopore long reads.

**Tool:** NanoPlot v1.41.6

**Output**

qc/14_long_reads_raw_NanoPlot-report.html

### ii. Quality Filtering and Post-Filtering QC

Raw Nanopore long-read sequencing data was quality-filtered using Fastplong to remove short and low-quality reads.

**Input file**

/mnt/d/Metagenomics/ERR14838507.fastq.gz

The original compressed FASTQ file containing raw Nanopore sequencing reads was used as input for quality filtering.

**Tool:** Fastplong v0.3.0

**Filtering Parameters**

- Minimum read length: 500 bp

- Quality threshold: Q10

- Adapter trimming was disabled to preserve the original read sequences.

**Output File**

cleaned_reads/filtered_long_reads_fastplong/ERR14838507.qc.fq.gz

**Post-filtering NanoPlot QC**

qc/16_long_reads_filtered_NanoPlot-report.html

**Read-Count Summary**

| Metric                        | Before Filtering   | After Filtering |
|-------------------------------|--------------------|-----------------|
|Total reads                    | 7,294,984          | 6,309,145       |
|Total bases (Gb)               | 32.23              | 31.89           |
|Q20 bases (%)                  | 86.96%             | 86.96%          |
|Q30 bases (%)                  | 69.81%	           | 69.80%          |

- Approximately 13.51% (985,839) of reads were removed, accounting for only 1.06% (0.34) of the total bases. This indicates that most removed reads were relatively short.

### iii. Host (Human) Removal from ONT Long Reads

To identify and remove potential human host-derived sequences from quality-filtered (ONT) long reads by aligning sequencing reads against the human reference genome (hg38) and extracting unmapped reads for downstream metagenomic analysis.

**Tools**

- Minimap2 (v2.26-r1175)

- Samtools (v1.16.1)

**Input files**

- Quality-filtered ONT reads: ERR14838507.qc.fq.gz

- Human reference genome: hg38.fa

Quality-filtered ONT long reads were aligned against the human reference genome (hg38) using Minimap2 with the *map-ont preset*. The resulting SAM file was processed using Samtools to identify and extract unmapped reads. The extracted FASTQ file was subsequently validated, and alignment statistics, a summary report, and execution logs were generated.

**Output files**

reads_ERR14838507.fastq.gz

This file contains the extracted unmapped reads intended for downstream metagenomic analysis.

| Metric                        | Count            |
|-------------------------------|------------------|
|Total input reads              |   6,309,145      |
|Mapped reads                   |      0           |
|Unmapped reads                 |   6,309,145      |
|Extracted reads                |   6,309,145      |
|FASTQ validation               |    PASSED        |

**Intermediate Outputs**

- ERR14838507.host_alignment.sam – Minimap2 alignment file

- 18_ERR14838507_host_removal_fastq_extraction_summary.txt – Extraction summary report

- FASTQ extraction was successful; however, zero reads mapped to hg38, requiring further verification of host removal.

### iv. Host mapping cross validation (ONT Long Reads)

To validate the Minimap2 alignment workflow - A positive control was performed by generating 50 synthetic human reads (5,000 bp each) from hg38 and aligning them using Minimap2 *(map-ont)*. Samtools was used to calculate mapping statistics to validate the alignment workflow and investigate the zero-mapping result observed during host removal.

**Input file**

- Human reference genome: references/hg38/hg38.fa
  
- Reference index: hg38.fa.fai

**Output file**

**Result summary**

| Metric                        |    Result         |
|-------------------------------|-------------------|
|Synthetic reads                |     50            |
|Read length                    |    5,000 bp       |
|Total SAM records              |     55            |
|Mapped records                 |     55            |
|Unmapped records               |     0             |
|Mapping percentage             |    100%           |

**Conclusion** Minimap2 successfully aligned the synthetic human reads to hg38, confirming that the reference and alignment workflow can detect human sequences.

- Post-host-removal ONT reads were subjected to quality control using NanoPlot v1.41.6 to assess read quality and length distribution.
  
Output 

## 4. Metagenomic Assembly for short reads and longs reads 

Metagenomic assembly is the process of combining sequencing reads to reconstruct longer DNA sequences called contigs. It can be performed using both **short-read** and **long-read** sequencing data separately with their respective tools. We perform assembly to reconstruct genomic fragments from microbial communities, making it easier to identify microorganisms, enabling the detection and characterization of prophages and other viral sequences within microbial communities. It also helps identify potential microbial hosts of these viruses and supports the study of virus–host relationships.

### i. Short-Read Metagenomic Assembly Using MEGAHIT

Paired-end short-read metagenomic assembly was performed using MEGAHIT to reconstruct longer DNA sequences (contigs) from overlapping sequencing reads. MEGAHIT uses iterative k-mer-based graph construction to generate contigs. The default `--min-contig-len` parameter was set to 200 bp, excluding contigs shorter than 200 bp from the final assembly.

**Tool** MEGAHIT v1.2.9 

**Input files**

- R1: ERR14836067_cleaned_1.fastq.gz
  
- R2: ERR14836067_cleaned_2.fastq.gz

**Output file**

- ERR14836067.contigs.fa – Final assembled contigs in FASTA format.

**Assembly results**

- Total contigs: 162,625
- Total assembly length: 295.93 Mb
- N50: 7,010 bp
- Minimum contig length: 200 bp
- Maximum contig length: 459,259 bp
- Average contig length: 1,819 bp

### ii. Quality Assessment of Short-Read Assembly Using QUAST

- The quality of the MEGAHIT-assembled contigs was assessed using QUAST **(Quality Assessment Tool for Genome Assemblies)**. QUAST evaluates assembly statistics, including contig length, N50, L50, and total assembly length, to assess the overall assembly quality.

**Tool:** QUAST v5.2.0 (--fast mode)

**Input file:**

ERR14836067.contigs.fa

**Output files:**

link

QUAST applied its default minimum contig length threshold of 500 bp for statistical calculations. Contigs shorter than 500 bp were excluded from the reported statistics. These shorter contigs remained present in the original MEGAHIT assembly FASTA file and were not deleted or modified.

**Assembly assessment results**

- Total assembly length	 - 272,961,575 bp (272.96 Mb)
- N50	- 9,239 bp
- L50 -	4,718
- auN -	32,370.4 bp
- GC content - Undefined
- Ns per 100 kbp - 0

### iii. Generation of Long-Read Quality Metadata Table

- This step was performed to extract read-level information from host-removed ONT long reads before subsampling. Read ID, sequence length, and average Phred quality score were calculated for each read.
  
- This metadata was generated to support subsequent random read selection based on the target sequencing yield. No read filtering or downsampling was performed at this stage.

**Tools:** Python 3, Biopython, NumPy, gzip, and the NanoPlot/NanoGet-compatible ave_qual method.

**Input file:**

reads_ERR14838507.fastq.gz — Host-removed ONT long-read FASTQ file.

**Output files:**

- read_qual_ERR14838507.tsv — Metadata table containing read ID, read length, and average quality score.
- read_qual_ERR14838507_summary.txt — Processing summary

**Results:**

- Total reads processed	- 6,309,145
- Total bases -	31,892,219,489
- Total sequencing yield - 31.89 Gb
- Read filtering -	None
- Downsampling -	Not performed

The generated metadata provides the read IDs and lengths required for the next step, where reads are randomly selected to achieve a predefined target sequencing yield. Average quality scores are also retained for read-level quality assessment.
