#!/usr/bin/env python3
# ---------------------------------------------------------------
# chop_bam_motif.py
#
# This script extracts and trims reads from a BAM file around a
# specific motif found in a reference contig.
#
# Pipeline:
#   1. Find the motif (exact or approximate) in the reference contig.
#   2. Define a fixed-size window centered on the motif midpoint.
#   3. From the BAM, extract reads that *fully span* this window.
#   4. Trim each read to the subsequence mapping to this region.
#   5. Write trimmed reads to FASTQ (for remapping or polishing).
#   6. Write a JSON log with summary statistics.
#
# Requirements:
#   pysam, pyfaidx, biopython, edlib
# ---------------------------------------------------------------

import argparse, json, sys
import edlib
import pysam
from pyfaidx import Fasta
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio import SeqIO


# ------------------ Helper: reverse complement ------------------
def revcomp(seq: str) -> str:
    """Return reverse complement of a DNA sequence."""
    return str(Seq(seq).reverse_complement())


# ------------------ Exact motif search ------------------
def find_exact_motif_in_contig(fasta, contig, motif):
    """
    Search for an exact (case-insensitive) motif match in both
    forward (+) and reverse (-) strands of the contig.
    Returns list of (position, strand).
    """
    seq = str(fasta[contig][:].seq).upper()
    motif_u = motif.upper()
    motif_rc = revcomp(motif_u)
    positions = []

    # Forward strand
    start = 0
    while True:
        idx = seq.find(motif_u, start)
        if idx == -1:
            break
        positions.append((idx, "+"))
        start = idx + 1

    # Reverse strand
    start = 0
    while True:
        idx = seq.find(motif_rc, start)
        if idx == -1:
            break
        positions.append((idx, "-"))
        start = idx + 1

    return positions


# ------------------ Approximate motif search (edlib) ------------------
def find_approx_motif_edlib(fasta, contig, motif, max_distance):
    """
    Perform approximate motif search using edlib (Levenshtein distance).
    Returns list of (start_position, edit_distance, strand).
    """
    seq = str(fasta[contig][:].seq).upper()
    motif_u = motif.upper()
    motif_rc = revcomp(motif_u)
    positions = []

    # Forward strand
    result_fwd = edlib.align(motif_u, seq, mode="HW", task="locations", k=max_distance)
    if result_fwd["editDistance"] != -1:
        for (start, end) in result_fwd["locations"]:
            positions.append((start, result_fwd["editDistance"], "+"))

    # Reverse strand
    result_rev = edlib.align(motif_rc, seq, mode="HW", task="locations", k=max_distance)
    if result_rev["editDistance"] != -1:
        for (start, end) in result_rev["locations"]:
            positions.append((start, result_rev["editDistance"], "-"))

    return positions


# ------------------ Compute window coordinates ------------------
def compute_window(midpoint, window_size, contig_len):
    """
    Compute [start, end) window centered on given midpoint.
    Adjusts for contig boundaries if needed.
    """
    half = window_size // 2
    ws, we = midpoint - half, midpoint + half

    # Adjust if window size off by 1 (odd/even mismatch)
    if (we - ws) < window_size:
        we += 1

    # Clip to contig edges
    if ws < 0:
        ws, we = 0, window_size
    if we > contig_len:
        we, ws = contig_len, contig_len - window_size

    return ws, we


# ------------------ Read coverage check ------------------
def read_fully_covers_window(aln, ws, we):
    """
    Return True if a read alignment fully spans [ws, we)
    in reference coordinates.
    """
    return (not aln.is_unmapped and
            aln.reference_start <= ws and aln.reference_end >= we)


# ------------------ Trim read to window region ------------------
def extract_window_from_read(aln, ws, we):
    """
    Extract the query (read) subsequence corresponding to [ws, we)
    on the reference. Returns SeqRecord or None.
    """
    pairs = aln.get_aligned_pairs(matches_only=False)
    qstart, qend = None, None

    # Map reference positions to query coordinates
    for qpos, rpos in pairs:
        if rpos == ws and qstart is None:
            qstart = qpos
        if rpos == we - 1:
            qend = qpos

    # Skip if window doesn’t map cleanly
    if qstart is None or qend is None:
        return None

    # Ensure qstart < qend
    if qstart > qend:
        qstart, qend = qend, qstart

    # Clamp indices
    qstart, qend = max(0, qstart), min(len(aln.query_sequence) - 1, qend)

    # Slice sequence and qualities
    seq = aln.query_sequence[qstart:qend+1]
    qual = (aln.query_qualities[qstart:qend+1]
            if aln.query_qualities else [40] * len(seq))

    return SeqRecord(
        Seq(seq),
        id=aln.query_name,
        description="",
        letter_annotations={"phred_quality": qual}
    )


# ------------------ Main workflow ------------------
def main():
    # ----- Parse command-line arguments -----
    ap = argparse.ArgumentParser(description="Trim BAM reads to window around motif, output FASTQ.")
    ap.add_argument("--bam", required=True, help="Input BAM file (sorted, indexed)")
    ap.add_argument("--ref", required=True, help="Reference FASTA file")
    ap.add_argument("--contig", required=True, help="Target contig name in reference")
    ap.add_argument("--motif", required=True, help="Motif sequence to locate")
    ap.add_argument("--window", type=int, required=True, help="Window size in bp centered on motif")
    ap.add_argument("--out", required=True, help="Output FASTQ filename")
    ap.add_argument("--log", default="chop_report.json", help="Output JSON summary log")
    ap.add_argument("--max-distance", type=int, default=0,
                    help="Allowed Levenshtein distance for approximate motif search")
    args = ap.parse_args()

    # ----- Load reference -----
    fasta = Fasta(args.ref)
    if args.contig not in fasta:
        sys.exit(f"Contig {args.contig} not found in reference")
    contig_len = len(fasta[args.contig])

    pos, mode, edit_distance = None, None, None

    # ----- Step 1: Exact motif search -----
    exact = find_exact_motif_in_contig(fasta, args.contig, args.motif)
    if len(exact) == 1:
        pos, strand = exact[0]
        mode, edit_distance = "exact", 0
    elif len(exact) > 1:
        sys.exit("Ambiguous exact motif hits found.")
    else:
        # ----- Step 2: Approximate motif search -----
        if args.max_distance > 0:
            approx = find_approx_motif_edlib(fasta, args.contig, args.motif, args.max_distance)
            if len(approx) == 0:
                sys.exit("No approximate motif hits found.")
            # Select best match with lowest edit distance
            best_ed = min(ed for _, ed, _ in approx)
            best_hits = [(p, strand) for p, ed, strand in approx if ed == best_ed]
            if len(best_hits) == 1:
                pos, strand = best_hits[0]
                mode, edit_distance = "approx", best_ed
            else:
                sys.exit(f"Ambiguous approximate hits: {len(best_hits)} positions with edit distance {best_ed}.")
        else:
            sys.exit("Motif not found.")

    # ----- Step 3: Define window centered on motif -----
    midpoint = pos + len(args.motif) // 2
    ws, we = compute_window(midpoint, args.window, contig_len)

    # ----- Step 4: Extract reads covering window -----
    bam = pysam.AlignmentFile(args.bam, "rb")
    records, total, kept = [], 0, 0
    for aln in bam.fetch(args.contig, ws, we):
        total += 1
        if not read_fully_covers_window(aln, ws, we):
            continue
        rec = extract_window_from_read(aln, ws, we)
        if rec:
            records.append(rec)
            kept += 1
    bam.close()

    # ----- Step 5: Write FASTQ output -----
    with open(args.out, "w") as f:
        SeqIO.write(records, f, "fastq")

    # ----- Step 6: Write JSON summary -----
    report = {
        "contig": args.contig,
        "motif": args.motif,
        "mode": mode,
        "motif_position": pos,
        "strand": strand,              # + or -
        "edit_distance": edit_distance,
        "window_start": ws,
        "window_end": we,
        "reads_examined": total,
        "reads_kept": kept
    }
    with open(args.log, "w") as fh:
        json.dump(report, fh, indent=2)

    print(f"✅ Done. {kept}/{total} reads kept. FASTQ written to {args.out}")


# ------------------ Entrypoint ------------------
if __name__ == "__main__":
    main()