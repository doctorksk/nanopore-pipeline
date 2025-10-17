# Nanopore basecalling and analysis pipeline

Analysis pipeline of Nanopore pod5 files. Basecalling, read trimming, optional mapping, and scripts to perform indel analysis of mapped reads using CRISPResso2.

## Directory structure

```
nanopore
├── analysis # Output directory
├── data # Input directory
├── dorado_model # ONT dorado installations
├── job # SLURM scripts and run-specific input files
├── model # Dorado basecalling models
├── reference # Reference FASTAs
└── scripts # Core bash and Python scripts
```
---
## Installation

### 1. Clone the repository
```bash
git clone https://github.com/doctorksk/nanopore-pipeline.git
cd nanopore-pipeline
```
### 2. Load Conda
```bash
module load miniconda3
```
### 3. Create Conda environments
Two environments are required:
```bash
# For basecalling, trimming, and mapping
conda env create -f nanopore_env.yml

# For CRISPResso2-based indel analysis
conda env create -f crispresso2_env.yml
```

## Usage

### 1. Prepare input data
Place your Nanopore sequencing output folder inside the `data/` folder as follows: `data/experiment_id`.

### 2. Configure the run

Edit `job/input_sheet.csv` file. Each row represent a different barcode.

Specify:
- flow_cell_id: ID of the flowcell (e.g. FBD73709)
- kit: barcoding kit used (e.g. SQK-NBD114-24)
- experiment_id: ID of the experiment to abalyze. Should match the appropriate folder name inside `data/`
- barcode: barcode number. Output files will not contain this barcode ID
- alias: custom id for the barcode. Output files will contain this identifier
- reference: path/to/reference/file to map reads with this barcode against

> **Note:** aliases may only include alphanumeric characters (Aa-Zz, 0-9), hyphens (-), and underscores (_). Do not include spaces or other symbols (e.g. +, $, &, etc.)

Edit the configuration file `job/config.sh`.

Specify:
- Dorado version and model path
- Path to your input CSV
- Trimming parameters
- Whether to perform mapping `map=TRUE or FALSE`

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

## Author

Developed by **Gabriel Martínez-Gálvez**
Woltjen Laboratory, Center for iPS Cell Research and Application (CiRA), Kyoto Universiry