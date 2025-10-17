#!/bin/bash
# This script orchestrates Dorado basecalling and demultiplexing
# for a Nanopore sequencing experiment.

# ------------------ Setup ------------------

cd ~/nanopore
# Move into the working project directory.

# Read configuration file (defines variables like dorado_dir, sheet_dir, etc.)
source job/config.sh

# Load Dorado basecaller by appending its directory to PATH.
export PATH=$PATH:$dorado_dir

# ------------------ Metadata extraction ------------------

# Extract experiment ID from the sample sheet (column 3 of row 2).
expid=$(awk -F',' 'NR==2 {print $3}' $sheet_dir)

# Extract kit name from the sample sheet (column 2 of row 2).
kit_name=$(awk -F',' 'NR==2 {print $2}' $sheet_dir)

# ------------------ Model specification ------------------

# Define Dorado basecalling model (here: R10.4.1 flow cell, E8.2 pore, 400bps, sup accuracy).
model=model/dna_r10.4.1_e8.2_400bps_sup@v5.2.0

# ------------------ Directory setup ------------------

# Define output directories for basecalling, demultiplexing, and logs.
basecall_out=analysis/$expid/basecalled/raw/
demux_out=analysis/$expid/demux/raw/
logs_out=analysis/$expid/logs

# Locate the pod5 directory (input files) inside the data folder for this experiment.
bam_dir=$(find data/$expid/ -type d -name pod5_skip)

# Create output directories if they don’t exist.
mkdir -p $logs_out $basecall_out $demux_out

# Save a copy of the config and sample sheet files to the logs folder for reproducibility.
cp job/config.sh $logs_out
cp $sheet_dir $logs_out

# ------------------ Main execution ------------------

# Run basecalling script: takes model, pod5 directory, kit name, and output folder.
bash scripts/basecall_pod5.sh \
    "$model" \
    "$bam_dir" \
    "$kit_name" \
    "$basecall_out"

# Run demultiplexing script: uses kit, sample sheet, basecalling output, and demux folder.

# Create a Dorado-compatible sample sheet with only the first 5 columns
sheet_dir_dorado=$logs_out/sample_sheet_dorado.csv
cut -d',' -f1-5 $sheet_dir > $sheet_dir_dorado

# Call demux script with the reduced sheet
bash scripts/demux_bam.sh \
    "$kit_name" \
    "$sheet_dir_dorado" \
    "$basecall_out" \
    "$demux_out"