#!/bin/bash
# basecall_pod5.sh
# This script performs basecalling from POD5 files using Dorado,
# demultiplexes with barcodes, and generates QC plots with NanoPlot.

# ------------------ Input arguments ------------------
basecall_model=$1   # Path or name of Dorado basecalling model (e.g. dna_r10.4.1_e8.2_400bps_sup@v5.2.0)
pod5_dir=$2         # Input directory containing POD5 files
kit_name=$3         # Sequencing kit name (needed for correct barcode set)
outdir=$4           # Output directory for results

# ------------------ Basecalling ------------------

# Perform basecalling using Dorado.
# Options:
#   --no-trim           → Keep full-length reads (don’t trim adapters).
#   --kit-name          → Specify sequencing kit so Dorado knows which barcodes to expect.
#   --barcode-both-ends → Require that barcodes are present at both ends for assignment.
# Output: single BAM file with basecalled reads.
dorado basecaller $basecall_model \
    $pod5_dir \
    --no-trim \
    --kit-name $kit_name --barcode-both-ends \
    > $outdir/calls.bam

# ------------------ Summary statistics ------------------

# Generate a run summary (TSV format) from the BAM file.
# This contains per-read information like length, quality, and barcode assignment.
# Useful for QC and NanoPlot downstream.
dorado summary $outdir/calls.bam \
    > $outdir/summary.tsv

# ------------------ NanoPlot QC ------------------

# Run NanoPlot to visualize read length distribution, quality scores, etc.
# Options:
#   --loglength → log-transform read length axis for better visualization of spread.
#   --summary   → input is Dorado summary.tsv.
#   -o          → specify output directory for NanoPlot plots and reports.
NanoPlot --loglength --summary $outdir/summary.tsv \
    -o $outdir/nanoplot