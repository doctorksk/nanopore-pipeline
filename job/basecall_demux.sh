#!/bin/bash
# This script orchestrates dorado basecalling and demultiplexing
# for a Nanopore sequencing experiment.

# ------------------ Setup ------------------

# Read configuration file (defines variables like dorado_dir and model_dir).
source job/config.sh
# Auto-clean sample sheet for Windows line endings (i.e. "\r").
[[ -f "job/input_sheet.csv" ]] && tmp=$(mktemp) && tr -d '\r' < "job/input_sheet.csv" > "$tmp" && mv "$tmp" "job/input_sheet.csv"

# Load dorado basecaller by appending its directory to PATH.
export PATH=$PATH:dorado_model/$dorado_dir/bin/

# ------------------ Metadata extraction ------------------

# Extract experiment ID from the sample sheet (column 3 of row 2).
expid=$(awk -F',' 'NR==2 {print $3}' job/input_sheet.csv) 

# Extract kit name from the sample sheet (column 2 of row 2).
kit_name=$(awk -F',' 'NR==2 {print $2}' job/input_sheet.csv)

# ------------------ Model specification ------------------

# Define dorado basecalling model (default: R10.4.1 flow cell, E8.2 pore, 400bps, sup accuracy).
model=model/$model_dir

echo -e "Experiment: $expid\nKit: $kit_name\nBasecalling model: $model_dir"

# ------------------ Directory setup ------------------

# Define output directories for basecalling, demultiplexing, and logs.
basecall_out=analysis/$expid/basecalled/raw
demux_out=analysis/$expid/demux/raw
logs_out=analysis/$expid/logs

# Locate the pod5 directory (input files) inside the data folder for this experiment.
bam_dir=$(find data/$expid/ -type d -name pod5_skip)

# Create output directories if they don’t exist.
mkdir -p $logs_out $basecall_out $demux_out

# Save a copy of the config and sample sheet files to the logs folder for reproducibility.
cp job/config.sh $logs_out
cp job/input_sheet.csv $logs_out

# ------------------ Main execution ------------------

# Run basecalling script: takes model, pod5 directory, kit name, and output folder.
bash scripts/basecall_pod5.sh \
    "$model" \
    "$bam_dir" \
    "$kit_name" \
    "$basecall_out"

# Run demultiplexing script: uses kit, sample sheet, basecalling output, and demux folder.
# Create a temporary dorado-compatible sample sheet with only the first 5 columns of input_sheet.csv
sheet_dir_dorado=$logs_out/sample_sheet_dorado.csv
cut -d',' -f1-5 job/input_sheet.csv > $sheet_dir_dorado

# Call demux script with the reduced sheet
bash scripts/demux_bam.sh \
    "$kit_name" \
    "$sheet_dir_dorado" \
    "$basecall_out" \
    "$demux_out"

# Delete temporary file
rm $logs_out/sample_sheet_dorado.csv