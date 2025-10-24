#!/bin/bash
# trim_fastq.sh
# This script trims Nanopore reads based on quality and length thresholds using Chopper,
# then generates quality control (QC) plots for each barcode using NanoPlot.

# ------------------ Input arguments ------------------
fastq_file=$1   # Input FASTQ file
quality=$2      # Minimum average read quality to retain (e.g. 10)
minlength=$3    # Minimum read length (bp) to retain
maxlength=$4    # Maximum read length (bp) to retain
outdir=$5       # Output directory for trimmed reads and QC reports

# ------------------ Read trimming ------------------

#   Use Chopper to filter reads by quality and length thresholds.
base=$(basename "$fastq_file" .fastq)

cat "$fastq_file" | \
    chopper --quality $quality --minlength $minlength --maxlength $maxlength \
    > $outdir/${base}_trimmed.fastq

# ------------------ NanoPlot QC ------------------
# Generate QC plots for the trimmed FASTQ file.
# Options:
#   --loglength → log-transform length axis for clearer visualization.
#   --fastq     → input FASTQ file.
#   -o          → output directory for NanoPlot reports.
NanoPlot --loglength --fastq "$outdir/${base}_trimmed.fastq" \
    -o "$outdir/nanoplot/$base/"