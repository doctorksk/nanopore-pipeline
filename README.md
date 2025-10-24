# Nanopore basecalling and analysis pipeline

Analysis pipeline of Nanopore pod5 files. Basecalling, read trimming, optional mapping, and scripts to perform indel analysis of mapped reads using CRISPResso2.

## Directory structure

```
nanopore_pipeline/
├── analysis/ # Output directory
├── data/ # Input directory
├── dorado_model/ # ONT dorado installations
├── job/ # SLURM scripts and run-specific input files
├── model/ # Dorado basecalling models
├── reference/ # Reference FASTAs
└── scripts/ # Core bash and Python scripts
```
---
## Installation

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
Two environments are required:
```bash
# For basecalling, trimming, and mapping
conda env create -f nanopore_env.yml

# For CRISPResso2-based indel analysis
conda env create -f crispresso2_env.yml
```

### 4. Download the dorado installation and basecalling models

Follow instructions [here](https://github.com/nanoporetech/dorado#installation) to download the latest dorado installation (i.e. dorado-x.y.z-linux-x64). Decompress the downloaded file and transfer the uncompressed folder inside the `dorado_model/` folder.

Grant dorado execution privileges by running:

```bash
chmod +x dorado_model/bin/dorado
```

Verify dorado installation by running:
```bash
dorado_model/bin/dorado --version
```

To ensure that the pipeline can work without an internet connection, download all available dorado basecalling models by running:

```bash
cd model
../dorado_model/bin/dorado download --model all
cd ..
```

### 5. Download appropriate reference FASTA files for mapping

Download the appropriate reference genomes or amplicons for minimap2 mapping and place it inside the `reference` folder. For example, the hg38 (GRCh38) analysis set `hg38.analysisSet.fa.gz` from UCSC found [here](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/analysisSet/).

## Usage

### 1. Load input data
Place your Nanopore sequencing output folder inside the `data/` folder as follows: `data/experiment_id`.

### 2. Configure the run

Edit `job/input_sheet.csv` file. Each row represents a different barcode. In case the file is corrupted, run the following, edit `job/input_sheet.csv` and try again.

```bash
rm job/input_sheet.csv
cp job/input_sheet_template.csv job/input_sheet.csv
```

Specify:
- **flow_cell_id:** ID of the flowcell (e.g. FBD73709)
- **kit:** barcoding kit used (e.g. SQK-NBD114-24)
- **experiment_id:** ID of the experiment to abalyze. Should match the appropriate folder name inside `data/`
- **barcode:** barcode number. Output files will not contain this barcode ID
**- alias:** custom id for the barcode. Output files will contain this identifier
- **reference:** *path/to/reference/file* that will be used to map reads with this barcode against
> **Note:** aliases may **ONLY** include alphanumeric characters (Aa-Zz, 0-9) and hyphens (-). **DO NOT** include spaces, underscores (_), or other symbols (e.g. +, $, &, etc.)
- **quality:** minimum average read quality for trimming
- **minlength:** minimum read length for trimming
- **maxlength:** maximum read length for trimming

Edit the configuration file `job/config.sh`.

Specify:
- Dorado version and model path
- Whether to perform mapping after read trimming: `map=TRUE` or `map=FALSE`

### 3. Run the pipeline

The pipeline is divided into two larger SLURM processes. The first process basecalls pod5 reads and demultiplexes them by barcode number. The second process trims reads and maps them against the specified reference files in `job/input_sheet.csv`.

To submit both SLURM processes:
```bash
jid1=$(sbatch --parsable job/slurm_basecall.sh)
sbatch --dependency=afterok:$jid1 job/slurm_trim_map.sh
```

Alternatively, users can run each process manually:

```bash
sbatch job/slurm_basecall.sh
```

```bash
sbatch job/slurm_trim_map.sh
```
> **Note:** Trimming and mapping can only happen on fully basecalled and demultiplexed files.

---
Running the pipeline will create the `slurm_logs` folder containing standard output and standard error files from SLURM and the `analysis/experiment_id` folder with the following directory structure:

```
analysis/experiment_id/
├── basecalled/ # Basecalling output folder
│   └── raw/ # Raw dorado basecalled data
│       ├── calls.bam # Unaligned output bam file
│       ├── summary.tsv # Sequencing summary file
│       └── nanoplot/ # NanoPlot diagnostic files
├── demux/ # Demultiplexing output folder
│   ├── raw/ # Raw dorado demultiplexed data
│   │   ├── run-id_alias.fastq # Demultiplexed reads by alias (barcode)
│   │   ├── run-id_unclassified.fastq # Unclassified reads
│   │   └── nanoplot/ # NanoPlot diagnostic files
│   ├── trimmed/ # Read trimming output folder
│   │   ├── run-id_alias_trimmed.fastq # Trimmed reads by alias (barcode)
│   │   └── nanoplot/ # Nanoplot diagnostic files
│   └── mapped/ (optional) # Read mapping output folder
│       ├── mm2_run-id_alias_trimmed.bam # Mapped reads by alias (barcode)
│       ├── mm2_run-id_alias_trimmed.bam.bai # Index files by alias (barcode)
│       └── nanoplot/ # NanoPlot diagnostic files
└── logs
    ├── config.sh # Copy of config file used to generate the data
    └── input_sheet.csv # Copy of the input sheet used to generate the data
```

## Author

Developed by **Gabriel Martínez-Gálvez**

Woltjen Laboratory, Center for iPS Cell Research and Application (CiRA), Kyoto Universiry