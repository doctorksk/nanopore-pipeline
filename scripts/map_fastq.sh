#!/bin/bash
# map_fastq.sh
# This script maps Nanopore reads to a reference genome using Minimap2,
# filters and sorts the alignments with Samtools, and generates QC plots with NanoPlot.
#
# ------------------ Input arguments ------------------
fastq=$1    # Input FASTQ file containing Nanopore reads
ref=$2      # Reference FASTA file for alignment
outdir=$3   # Output directory for BAM files and QC plots

# ------------------ Mapping ------------------

# Run Minimap2 for long-read alignment.
# Options:
#   -a              → Output in SAM format.
#   -x map-ont      → Preset optimized for Oxford Nanopore reads.
#   -t 4            → Use 4 CPU threads.
#   --secondary=no  → Suppress secondary alignments (keep only primary hits).
# Output is piped directly to Samtools for filtering and sorting.
base=$(basename "$fastq" .fastq)

minimap2 -ax map-ont -t 4 --secondary=no "$ref" "$fastq" | \
    samtools view -hb -q 20 -F 2052 | samtools sort > "$outdir/mm2_${base}.bam"

# ------------------ Post-processing ------------------

# Samtools filtering and sorting:
#   view -hb     → Convert SAM to BAM (binary) and keep only mapped reads.
#   -q 20        → Keep only reads with mapping quality ≥ 20.
#   -F 2052      → Exclude supplementary and QC-failed reads.
#   sort         → Sort BAM by genomic coordinates.
# Then index the final BAM for efficient downstream access.
samtools index "$outdir/mm2_${base}.bam"

# ------------------ NanoPlot QC ------------------

# Generate NanoPlot summary and read length plots from the BAM file.
# Options:
#   --loglength → log-transform read length axis for better visualization.
#   --bam       → input BAM file.
#   -o          → output directory for NanoPlot reports.
NanoPlot --loglength --bam "$outdir/mm2_${base}.bam" \
    -o "$outdir/nanoplot/${base}/"