#!/bin/bash
# This script orchestrates adapter/quality trimming
# and optionally read mapping depending on the config.

# ------------------ Setup ------------------

# cd ~/nanopore
# Move into the project working directory.

# Load experiment configuration variables (sheet_dir, quality, minlength, maxlength, ref, map, etc.)
source job/config.sh

# ------------------ Metadata extraction ------------------

# Extract experiment ID from the sample sheet (column 3 of row 2).
expid=$(awk -F',' 'NR==2 {print $3}' $sheet_dir)

# ------------------ Directory setup ------------------

# Define output directories for raw demux, trimmed reads, and logs.
demux_out=analysis/$expid/demux/raw/
trim_out=analysis/$expid/demux/trimmed/
logs_out=analysis/$expid/logs

# Create the required directories if they don’t already exist.
mkdir -p $trim_out $logs_out

# ------------------ Main execution ------------------

# Run trimming script: input raw demux folder, quality/min/max lengths, output trimmed folder.
bash scripts/trim_fastq.sh \
    $demux_out \
    $quality \
    $minlength \
    $maxlength \
    $trim_out

# ------------------ Optional mapping ------------------

# Check the "map" variable from config.sh to decide if mapping should run.
if [ "$map" = "TRUE" ]; then 
    
    # Define mapping output directory.
    map_out=analysis/$expid/demux/mapped/
    mkdir -p $map_out
    
    # Run mapping script: input trimmed reads, reference fasta, and output mapping folder.
    bash scripts/map_fastq.sh \
        $trim_out \
        $ref \
        $map_out
fi

# ------------------ Optional mapping ------------------

# Check the "map" variable from config.sh to decide if mapping should run.
if [ "$map" = "TRUE" ]; then 
    
    # Define mapping output directory.
    map_out=analysis/$expid/demux/mapped/
    mkdir -p "$map_out"
    
    # Loop over trimmed FASTQs
    for fastq in "$trim_out"/*.fastq; do
        # Extract alias from filename: runid_alias_trimmed.fastq → alias
        base=$(basename "$fastq")
        alias=$(echo "$fname" | sed -E 's/^[^_]+_([^_]+.*)_trimmed\.fastq/\1/')

        # Look up reference path from sample sheet (col 6, matching alias in col 5)
        ref=$(awk -F',' -v a="$alias" '$5==a {print $6}' "$sheet_dir")

        if [ -z "$ref" ]; then
            echo "ERROR: No reference found in sample sheet for alias $alias"
            exit 1
        fi

        # Run mapping
        bash scripts/map_fastq.sh "$fastq" "$ref" "$map_out"
    done
fi