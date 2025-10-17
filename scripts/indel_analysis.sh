#!/bin/bash

# indel_analysis.sh
# This script performs indel analysis around a target motif using Nanopore reads.
# It trims reads to a motif-centered window, checks motif orientation in the reference,
# and runs CRISPResso for indel quantification.

# ------------------ Input arguments ------------------
bam_in=$1       # Input BAM file (aligned reads)
ref=$2          # Reference FASTA file
header=$3       # Contig header line (from FASTA; includes contig name and optional description)
motif_seq=$4    # Target motif (spacer or protospacer sequence)
window_size=$5  # Window size (bp) centered around motif
sample_name=$6  # Sample name (used for output directory)

# ------------------ Setup ------------------

# Extract contig name (everything before the first space in the header)
contig=$(echo $header | cut -d ' ' -f1)

# Create a dedicated output directory for this sample
mkdir -p "./$sample_name"

# ------------------ Trim reads around motif ------------------

# Use `chop_bam_motif.py` to:
#   1. Locate the motif (exact or approximate) in the reference.
#   2. Define a window centered on the motif.
#   3. Extract and trim reads that fully span this window.
# Output:
#   - Trimmed reads in FASTQ format.
#   - JSON report with motif match info and window coordinates.
python ~/nanopore/scripts/chop_bam_motif.py \
    --bam "$bam_in" \
    --ref "$ref" \
    --contig "$contig" \
    --motif "$motif_seq" \
    --window "$window_size" \
    --out "$sample_name/chopped.fastq" \
    --log "$sample_name/report.json" \
    --max-distance 2

# ------------------ Extract amplicon sequence ------------------

# Retrieve window start and end positions from the JSON report
amplicon_start=$(jq -r '.window_start' "$sample_name/report.json")
amplicon_end=$(jq -r '.window_end' "$sample_name/report.json")

# Extract the amplicon sequence from the reference using samtools faidx
# and clean FASTA formatting (uppercase, single line, no header)
crispresso_amplicon=$(samtools faidx "$ref" "${contig}:${amplicon_start}-${amplicon_end}" | \
    tail -n +2 | tr -d '\n' | tr 'acgt' 'ACGT')

# Convert motif sequence to uppercase for consistency
motif_seq=$(echo "$motif_seq" | tr 'acgt' 'ACGT')

# ------------------ Check motif orientation ------------------

# Verify whether the motif is present in the extracted amplicon sequence.
# If not, check the reverse complement orientation and adjust accordingly.
if [[ "$crispresso_amplicon" == *"$motif_seq"* ]]; then
    echo "Spacer sequence found in reference"
else
    # Compute reverse complement of the amplicon
    revcomp=$(echo "$crispresso_amplicon" | rev | tr 'ACGTacgt' 'TGCAtgca')
    if [[ "$revcomp" == *"$motif_seq"* ]]; then
        echo "Spacer sequence found in reverse complement orientation"
        crispresso_amplicon=$revcomp
    else
        echo "Spacer sequence not found in any orientation of reference"
    fi
fi

# ------------------ Run CRISPResso ------------------

# Perform indel quantification using CRISPResso.
# Options:
#   -p 32                → Use 32 threads.
#   --ignore_substitutions → Ignore base substitutions (indels only).
#   -r1                  → Input FASTQ file with motif-centered reads.
#   -g                   → Target (guide) sequence.
#   -a                   → Reference amplicon sequence.
#   -n                   → Sample name (used for naming output files).
#   -o                   → Output directory.
CRISPResso -p 32 \
    --ignore_substitutions \
    -r1 "$sample_name/chopped.fastq" \
    -g "$motif_seq" \
    -a "$crispresso_amplicon" \
    -n "$sample_name" \
    -o "$sample_name/"