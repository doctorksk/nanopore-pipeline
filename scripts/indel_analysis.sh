#!/bin/bash

# indel_analysis.sh
# This script performs indel analysis around a target motif using Nanopore reads.
# It trims reads to a motif-centered window, checks motif orientation in the reference,
# and runs CRISPResso for indel quantification.

# ------------------ Input arguments ------------------
bam_in=$1             # Input BAM file (aligned reads)
ref=$2                # Reference FASTA file
header=$3             # Contig header line (from FASTA)
motif_seq=$4          # Target motif (spacer or protospacer sequence)
window_size=$5        # Window size (bp) centered around motif
sample_name=$6        # Sample name (used for output directory)
expected_amplicon=$7  # (Optional) Edited amplicon sequence

# ------------------ Setup ------------------

# Extract contig name (everything before the first space in the header)
contig=$(echo $header | cut -d ' ' -f1)

# Create a dedicated output directory for this sample
# mkdir -p "./$sample_name"

# Derive output directory relative to the BAM file
bam_dir=$(dirname "$bam_in")
out_root="$(dirname "$bam_dir")/crispresso"
outdir="$out_root/$sample_name"
mkdir -p $outdir


# ------------------ Trim reads around motif ------------------

# Use `chop_bam_motif.py` to:
#   1. Locate the motif (exact or approximate) in the reference.
#   2. Define a window centered on the motif.
#   3. Extract and trim reads that fully span this window.
# Output:
#   - Trimmed reads in FASTQ format.
#   - JSON report with motif match info and window coordinates.
python scripts/chop_bam_motif.py \
    --bam "$bam_in" \
    --ref "$ref" \
    --contig "$contig" \
    --motif "$motif_seq" \
    --window "$window_size" \
    --out "$outdir/chopped.fastq" \
    --log "$outdir/report.json" \
    --max-distance 2

# ------------------ Extract amplicon sequence ------------------

# Retrieve window start and end positions from the JSON report
amplicon_start=$(jq -r '.window_start' "$outdir/report.json")
amplicon_end=$(jq -r '.window_end' "$outdir/report.json")
crispresso_amplicon=$(jq -r '.window_sequence' "$outdir/report.json")

# Convert motif sequence to uppercase for consistency
motif_seq=$(echo "$motif_seq" | tr 'acgt' 'ACGT')

# ------------------ Check motif orientation ------------------

# Verify whether the motif is present in the extracted amplicon sequence.
# If not, check the reverse complement orientation and adjust accordingly.
if [[ "$crispresso_amplicon" == *"$motif_seq"* ]]; then
    echo "Spacer sequence successfully found in reference"
else
    # Compute reverse complement of the amplicon
    revcomp=$(echo "$crispresso_amplicon" | rev | tr 'ACGTacgt' 'TGCAtgca')
    if [[ "$revcomp" == *"$motif_seq"* ]]; then
        echo "Spacer sequence successfully found in reverse complement orientation"
        crispresso_amplicon=$revcomp
    else
        echo "Spacer sequence not found in any orientation of reference"
    fi
fi
# ------------------ Run CRISPResso ------------------

# Construct base CRISPResso command
crispresso_cmd=(
  CRISPResso -p 32
  --ignore_substitutions
  -r1 "$outdir/chopped.fastq"
  -g "$motif_seq"
  -a "$crispresso_amplicon"
  -n "$sample_name"
  -o "$outdir/"
)

# If user provided expected amplicon (HDR or PE), include it
if [[ -n "$expected_amplicon" ]]; then
    echo "Including expected amplicon in CRISPResso run."
    crispresso_cmd+=(-e "$expected_amplicon")
fi

# Execute CRISPResso
"${crispresso_cmd[@]}"