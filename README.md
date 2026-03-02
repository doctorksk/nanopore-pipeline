# Nanopore basecalling and analysis pipeline

Analysis pipeline of Nanopore pod5 files compatible with Kyoto University's C2 HPC cluster via SLURM scheduling. Pipeline includes basecalling, read trimming, mapping (optional), and scripts to perform indel analysis of mapped reads using CRISPResso2.

> **IMPORTANT:** This pipeline is not compatible with dorado version 1.2.0 or later. The latest supported version is dorado 1.1.1.

## Directory structure

```
nanopore_pipeline/
├── analysis/       → Output directory
├── data/           → Input directory
├── dorado_model/   → ONT dorado installations
├── job/            → SLURM scripts and run-specific input files
├── model/          → Dorado basecalling models
├── reference/      → Reference FASTAs
└── scripts/        → Core bash and Python scripts
```
---
## Installation
> **IMPORTANT:** You only need to run installation the first time.

### 1. Clone the nanopore-pipeline repository
```bash
git clone https://github.com/doctorksk/nanopore-pipeline.git
cd nanopore-pipeline
```
### 2. Load conda
```bash
module load miniconda3
```
### 3. Create conda environments
To basecall, trim, and map create the `nanopore_env` environment by running:
```bash
# For basecalling, trimming, and mapping
conda env create -f nanopore_env.yml
```
(Optional)
For automated CRISPResso2 indel analyses, create the `crispresso2_env` environment by running:
```bash
# For CRISPResso2-based indel analysis
conda env create -f crispresso2_env.yml
```

### 4. Download the dorado installation and basecalling models

#### 4.1. Download dorado
Follow the instructions in the [official dorado repository](https://github.com/nanoporetech/dorado#installation) to obtain the latest comparible dorado release (e.g. *dorado-1.1.1-linux-x64*). 

#### 4.2. Extract and move the dorado folder
Decompress the downloaded file, and move the extracted folder (e.g. `dorado-x.y.z-linux-x64/`) into the `dorado_model/`  folder.

The resulting structure should look like:
```
dorado_model/
└── dorado-x.y.z-linux-x64/
    ├── bin/
    └── ...
```
#### 4.3 Grant dorado execution permision
Give dorado execution privileges by running:

```bash
chmod +x dorado_model/[dorado_installation]/bin/dorado
```
> Replace `[dorado_installation]` with the actual folder name (e.g. `dorado-x.y.z-linux-x64`).

#### 4.4 Verify dorado installation
Verify the dorado installation by running:
```bash
dorado_model/[dorado_installation]/bin/dorado --version
```
> Replace `[dorado_installation]` with the actual folder name (e.g. `dorado-x.y.z-linux-x64`).

If installed correctly, running the command above should return something similar to:
```bash
[time stamp] [info] Running: "--version"
1.1.1+e72f1492
```

#### 4.5 Download basecalling models
To ensure that the pipeline can work without an internet connection, download all available dorado basecalling models by running:

```bash
cd model
../dorado_model/[dorado_installation]/bin/dorado download --model all
cd ..
```
> Replace `[dorado_installation]` with the actual folder name (e.g. `dorado-x.y.z-linux-x64`).

### 5. Download appropriate reference FASTA files for mapping

Download the appropriate reference genomes or amplicons for read mapping and place it inside the `reference/` folder. For example, the hg38 (GRCh38) analysis set `hg38.analysisSet.fa.gz` from UCSC found [here](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/analysisSet/).

## Usage

### Dorado basecalling, trimming, and mapping

#### 1. Load input data
Place your Nanopore sequencing output folder inside the `data/` folder as follows: `data/[experiment_id]/`.

#### 2. Configure the run

Edit `job/input_sheet.csv` file. Each row represents a different barcode. 

> **Note:** In case `job/input_sheet.csv` becomes corrupted, delete it and remake it by copying and renaming it from the template file `job/input_sheet_template.csv` by running the following:
> ```bash
> rm job/input_sheet.csv
> cp job/input_sheet_template.csv job/input_sheet.csv
> ```

Specify:
- **flow_cell_id:** ID of the flowcell (e.g. FBD73709)
- **kit:** barcoding kit used (e.g. SQK-NBD114-24)
- **experiment_id:** ID of the experiment to analyze. Should match the appropriate folder name inside `data/`
- **barcode:** barcode number. *Output file names *WILL NOT* contain this barcode ID*
- **alias:** custom id for the barcode (40 characters maximum including '-'). *Output file names *WILL* contain this identifier*
> **Note:** aliases may **ONLY** include alphanumeric characters (Aa-Zz, 0-9) and hyphens (-). **DO NOT** include spaces, underscores (_), or other symbols (e.g. +, $, &, etc.)
- **reference:** path relative to the `reference/` folder (e.g. *grch38/hg38.analysisSet.fa.gz*, **NOT** *reference/grch38/hg38.analysisSet.fa.gz*)
> **Note:** you may leave reference entries empty for barcodes you do not wish to map 
- **quality:** minimum average read quality for trimming
- **minlength:** minimum read length to keep after trimming
- **maxlength:** maximum read length to keep after trimming

Edit the configuration file `job/config.sh` only if you need to change dorado versions or the dorado basecalling model (default: `dorado-1.1.1-linux-x64` and `dna_r10.4.1_e8.2_400bps_sup@v5.2.0`, respectively).

Specify:
- **dorado_dir:** name of the uncompressed folder with the desired dorado version (e.g. *dorado-1.1.1-linux-x64*)
- **model_dir:** name of the desired basecalling model as it appears inside the `model/` folder (e.g. *dna_r10.4.1_e8.2_400bps_sup@v5.2.0*)

> **Note:** In case `job/config.sh` is corrupted, delete it and remake it by copying and renaming it from the template file `job/config_template.sh` by running the following:
> ```bash
> rm job/config.sh
> cp job/config_template.sh job/config.sh
> ```

#### 3. Run the pipeline

The pipeline is divided into two larger SLURM jobs. The first job basecalls pod5 reads and demultiplexes them by barcode. The second job trims reads and optionally maps them against the reference files specified in `job/input_sheet.csv`.

To basecall, demultiples, trim (and map), submit both SLURM jobs by running the following:
```bash
jid1=$(sbatch --parsable job/slurm_basecall.sh)
sbatch --dependency=afterok:$jid1 job/slurm_trim_map.sh
```

Alternatively, users can run each job separately by running:

```bash
sbatch job/slurm_basecall.sh
```

```bash
sbatch job/slurm_trim_map.sh
```
> **Note:** Trimming and mapping can only happen on fully basecalled and demultiplexed files.

Running the pipeline will create the `slurm_logs/` folder containing standard output and standard error files and the `analysis/experiment_id/` folder with the following directory structure:

```
analysis/experiment_id/
├── basecalled/                                 → Basecalling output folder
│   └── raw/                                    → Raw dorado basecalled data
│       ├── calls.bam                           → Unaligned dorado basecalling output bam file
│       ├── summary.tsv                         → Sequencing summary file
│       └── nanoplot/                           → NanoPlot basecalling diagnostic files
├── demux/                                      → Demultiplexing output folder
│   ├── raw/                                    → Raw dorado demultiplexed data
│   │   ├── run-id_alias.fastq                  → Demultiplexed reads by alias (barcode)
│   │   ├── run-id_unclassified.fastq           → Unclassified reads
│   │   └── nanoplot/                           → NanoPlot demultiplexed diagnostic files
│   ├── trimmed/                                → Read trimming output folder
│   │   ├── run-id_alias_trimmed.fastq          → Trimmed reads by alias (barcode)
│   │   └── nanoplot/                           → Nanoplot diagnostic files of trimmed reads
│   └── mapped/ (optional)                      → Read mapping output folder
│       ├── mm2_run-id_alias_trimmed.bam        → Mapped reads by alias (barcode)
│       ├── mm2_run-id_alias_trimmed.bam.bai    → Index files by alias (barcode)
│       └── nanoplot/                           → NanoPlot diagnostic files of mapped reads
└── logs/
    ├── config.sh                               → Copy of config file used to generate the data
    └── input_sheet.csv                         → Copy of the input sheet used to generate the data
```
---
### Indel analysis of Nanopore reads with CRISPResso2

CRISPResso2 ([Pinello et al., 2016](https://www.nature.com/articles/nbt.3583); [Clement et al., 2019](https://www.nature.com/articles/nbt.3583)) is a computational tool that evaluates the outcomes of genome editing experiments subject to deep sequencing. However, it is known to encounter memory issues when processing long-read sequencing data such as that from Nanopore (see CRISPResso2 issues [#565](https://github.com/pinellolab/CRISPResso2/issues/565) and [#484](https://github.com/pinellolab/CRISPResso2/issues/484)). 

To address this limitation, the script `scripts/indel_analysis.sh` extracts read segments of a fixed length (window) surrounding a user-specified CRISPR protospacer from aligned BAM files, and runs CRISPResso2 on these shorter reads. By restricting indel quantification to shorter regions near the expected edit site, this approach avoids memory bottlenecks. 

This step is independent of the main pipeline and can be run multiple times per barcode using different reference contigs, DNA motifs, or window sizes.

#### Usage:

If using a SLURM system, connect to a computing node from the login node by running:

```bash
srun --pty -p cpu -c 32 bash
```
If needed, load conda:
```bash
module load miniconda3
```
Activate the CRISPResso2 environment by running:
```bash
conda activate crispresso2_env
```
Finally, run `scripts/indel_analysis.sh` using the arguments listed below:

```bash
bash scripts/indel_analysis.sh \
    analysis/[experiment_id]/demux/mapped/[bam_file.bam] \
    reference/[reference.fasta] \
    "[reference_contig]" \
    [protospacer_sequence] \
    [window_length] \
    [sample_name] \
    [expected_amplicon]
```

Arguments:
- **experiment_id:** experiment name matching the one present inside the `data/` and `analysis/` folders.
- **bam_file.bam:** input BAM file containing aligned reads
- **reference.fasta:** FASTA file used as the mapping reference
- **reference_contig:** contig name matching a header in the reference FASTA (e.g. chr16 for GRCh38)
- **protospacer_sequence:** target motif sequence (e.g. CRISPR guide RNA spacer) in 5' to 3' orientation
- **window_length:** window size (in bp) centered on the expected cut site (3 bp upstream of NGG PAM)
- **sample_name:** unique identifier used to label output folder and CRISPResso2 reports
- ***expected_amplicon:  (optional)*** expected amplicon after editing. The amplicon boundaries should correspond to the start and end of the reference region defined by `window_length`, centered on the expected Cas9 cleavage site (3 bp upstream of NGG PAM) 
> **Note:** if `[expected_amplicon]` is ommited, remove the final `\` after `[sample_name]`

#### Output

Running the script creates a new folder `crispresso/` under  `analysis/[experiment_id]/demux` with the following structure:

```
demux/
└── crispresso/                             → indel_analysis.sh output folder
│   └── sample_name/                                    
│       ├── chopped.fastq                   → Trimmed reads (windowed around motif)
│       ├── report.json                     → BAM trimming summary
│       ├── CRISPResso_on_sample_name.html  → CRISPResso2 HTML report
│       └── CRISPResso_on_sample_name/      → CRISPResso2 analysis files
└── ...
```

To visualize the HTML report, make sure to download the `CRISPResso_on_sample_name.html` file and the `CRISPResso_on_sample_name/` folder under the same directory.

---
## Author

Developed by **Gabriel Martínez-Gálvez**

Woltjen Laboratory, Center for iPS Cell Research and Application (CiRA), Kyoto University