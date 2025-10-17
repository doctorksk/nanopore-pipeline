#!/bin/bash
# demux_bam.sh
# This script demultiplexes reads from a BAM file using Dorado,
# separates them by barcode according to a sample sheet,
# and generates per-sample QC plots with NanoPlot.

# ------------------ Input arguments ------------------
kit_name=$1       # Sequencing kit name (e.g. SQK-RBK114-96)
sample_sheet=$2   # Sample sheet CSV linking barcodes to sample names
input_bam=$3      # Input BAM file with basecalled reads
outdir=$4         # Output directory for demultiplexed reads and QC plots

# ------------------ Demultiplexing ------------------

# Perform barcode-based demultiplexing using Dorado.
# Options:
#   --kit-name       → Specify the sequencing kit to identify correct barcode set.
#   --sample-sheet   → Provide CSV linking barcodes to sample identifiers.
#   --emit-fastq     → Output demultiplexed reads as FASTQ files (one per barcode).
# Output: one FASTQ file per barcode in the specified output directory.
dorado demux --kit-name $kit_name --sample-sheet $sample_sheet --emit-fastq \
    $input_bam \
    --output-dir $outdir

# ------------------ NanoPlot QC ------------------

# For each demultiplexed FASTQ file, generate NanoPlot QC visualizations.
# Options:
#   --loglength → log-transform read length axis for better visualization of spread.
#   --fastq     → input FASTQ file for NanoPlot.
#   -o          → specify output directory for each barcode’s NanoPlot report.
for file in $outdir/*.fastq; do
    base=$(basename "$file" .fastq)
    NanoPlot --loglength --fastq $file \
        -o $outdir/nanoplot/$base/
done