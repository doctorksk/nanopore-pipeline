#!/bin/bash
# This script orchestrates adapter/quality trimming and optional read mapping.

# ------------------ Setup ------------------

# Read configuration file (defines variables like dorado_dir and model_dir).
source job/config.sh
# Auto-clean sample sheet for Windows line endings.
[[ -f "job/input_sheet.csv" ]] && tmp=$(mktemp) && tr -d '\r' < "job/input_sheet.csv" > "$tmp" && mv "$tmp" "job/input_sheet.csv"

# ------------------ Metadata extraction ------------------

# Extract experiment ID from the sample sheet (column 3 of row 2).
expid=$(awk -F',' 'NR==2 {print $3}' job/input_sheet.csv)

# ------------------ Directory setup ------------------

# Define output directories for raw demux, trimmed reads, and logs.
demux_out=analysis/$expid/demux/raw
trim_out=analysis/$expid/demux/trimmed

# Create the required directories if they don’t already exist.
mkdir -p $trim_out

# ------------------ Main execution ------------------

# Loop over raw demux FASTQs
for fastq in "$demux_out"/*.fastq; do
    [[ $fastq == *_unclassified.fastq ]] && continue  # Skip unclassified reads

    base=$(basename "$fastq" .fastq)
    alias=$(echo "$base.fastq" | sed -E 's/^[^_]+_([^_]+.*)\.fastq/\1/')

    # Extract trimming parameters (cols 7–9) for this alias from the input_sheet.csv
    read quality minlength maxlength <<< $(awk -F',' -v a="$alias" '$5==a {print $7, $8, $9}' "job/input_sheet.csv")

    if [[ -z "$quality" || -z "$minlength" || -z "$maxlength" ]]; then
        echo "ERROR: Missing trim parameters for alias $alias in sheet"
        exit 1
    fi

    echo "→ Trimming $alias with quality=$quality, minlen=$minlength, maxlen=$maxlength"

    # Run trimming for this single FASTQ file
    bash scripts/trim_fastq.sh "$fastq" "$quality" "$minlength" "$maxlength" "$trim_out"

    # Look up reference path from sample sheet (col 6, matching alias in col 5)
    ref=$(awk -F',' -v a="$alias" '$5==a {print $6}' "job/input_sheet.csv")

    # If no reference entry found OR empty reference → skip
    if [ -z "$ref" ]; then
        echo "Skipping mapping for $alias (no reference specified)"
        continue
    fi

     # Define mapping output directory.
     map_out=analysis/$expid/demux/mapped
     mkdir -p "$map_out"

    # Run mapping for this single trimmed FASTQ file
    echo "Mapping $alias using reference $ref"
    bash scripts/map_fastq.sh "$trim_out/${base}_trimmed.fastq" "reference/$ref" "$map_out"
done