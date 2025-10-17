#!/bin/bash
# trim_fastq.sh
# This script trims Nanopore reads based on quality and length thresholds using Chopper,
# then generates quality control (QC) plots for each barcode using NanoPlot.

# ------------------ Input arguments ------------------
fastq_dir=$1    # Directory containing input FASTQ files (one per barcode)
quality=$2      # Minimum average read quality to retain (e.g. 10)
minlength=$3    # Minimum read length (bp) to retain
maxlength=$4    # Maximum read length (bp) to retain
outdir=$5       # Output directory for trimmed reads and QC reports

# ------------------ Read trimming ------------------

# For each FASTQ file:
#   - Skip unclassified reads (those not assigned to a barcode)
#   - Use Chopper to filter reads by quality and length thresholds.
#     Options:
#       --quality   → Minimum average read Q-score.
#       --minlength → Minimum read length (bp).
#       --maxlength → Maximum read length (bp).
#   - Output: trimmed FASTQ file for each barcode.
for file in $fastq_dir/*.fastq; do
    [[ $file == *_unclassified.fastq ]] && continue  # Skip unclassified reads
    
    base=$(basename "$file" .fastq)
    
    cat $file | \
        chopper --quality $quality --minlength $minlength --maxlength $maxlength \
        > $outdir/${base}_trimmed.fastq

    # ------------------ NanoPlot QC ------------------
    # Generate QC plots for each trimmed FASTQ file.
    # Options:
    #   --loglength → log-transform length axis for clearer visualization.
    #   --fastq     → input FASTQ file.
    #   -o          → output directory for NanoPlot reports.
    NanoPlot --loglength --fastq $outdir/${base}_trimmed.fastq \
        -o $outdir/nanoplot/$base/
done