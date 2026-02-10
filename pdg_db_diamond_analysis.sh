#!/bin/bash
# ==============================================
# PDG_DB DIAMOND BLASTP Analysis Pipeline
# Version: 1.0
# Description: Build database and run homology search
# Usage: bash pdg_db_diamond_analysis.sh [INPUT_FASTA]
# ==============================================

# ----------------------------
# 1. Set paths and parameters
# ----------------------------
# Set PDG_DB data directory (modify according to actual location)
PDG_DB_DIR="./PDG_DB"
PDG_DB_FASTA="${PDG_DB_DIR}/PDG_DB_protein.faa"   # PDG_DB sequence file
PDG_DB_ANNOT="${PDG_DB_DIR}/PDG_DB_gene_type.tsv"      # Annotation metadata file

# DIAMOND database name
DIAMOND_DB_NAME="pdg_db_diamond"

# Input query file (can be specified via command-line argument)
QUERY_FASTA="${1:-query.fasta}"

# Output result file prefix
OUTPUT_PREFIX="pdg_db_blastp_result"

# Set number of threads (adjust according to server configuration)
THREADS=8

# ----------------------------
# 2. Check required files
# ----------------------------
echo "=== Checking input files ==="
if [ ! -f "$PDG_DB_FASTA" ]; then
    echo "Error: PDG_DB sequence file not found: $PDG_DB_FASTA"
    echo "Please download from GitHub: https://github.com/Z-bioinfo/PDG_DB"
    exit 1
fi

if [ ! -f "$PDG_DB_ANNOT" ]; then
    echo "Warning: Annotation file not found: $PDG_DB_ANNOT (optional)"
fi

if [ ! -f "$QUERY_FASTA" ]; then
    echo "Error: Query sequence file not found: $QUERY_FASTA"
    echo "Usage: $0 [query_sequences.fasta]"
    exit 1
fi

# ----------------------------
# 3. Build DIAMOND database
# ----------------------------
echo ""
echo "=== Building DIAMOND database ==="
if [ -f "${DIAMOND_DB_NAME}.dmnd" ]; then
    echo "Existing database detected, skipping build step."
    echo "To rebuild, delete the file: ${DIAMOND_DB_NAME}.dmnd"
else
    echo "Building database..."
    diamond makedb \
        --in "$PDG_DB_FASTA" \
        --db "$DIAMOND_DB_NAME" \
        --threads "$THREADS"
    
    if [ $? -eq 0 ]; then
        echo "✓ Database built successfully: ${DIAMOND_DB_NAME}.dmnd"
    else
        echo "✗ Database build failed"
        exit 1
    fi
fi

# ----------------------------
# 4. Run BLASTP alignment
# ----------------------------
echo ""
echo "=== Running DIAMOND BLASTP alignment ==="
OUTPUT_FILE="${OUTPUT_PREFIX}.tsv"

diamond blastp \
    --db "$DIAMOND_DB_NAME" \
    --query "$QUERY_FASTA" \
    --out "$OUTPUT_FILE" \
    --outfmt 6 \
    --threads "$THREADS" \
    --evalue 1e-5 \
    --max-target-seqs 10 \
    --more-sensitive

if [ $? -eq 0 ]; then
    echo "✓ Alignment completed: $OUTPUT_FILE"
else
    echo "✗ Alignment failed"
    exit 1
fi

# ----------------------------
# 5. Optional: Add annotation information
# ----------------------------
if [ -f "$PDG_DB_ANNOT" ]; then
    echo ""
    echo "=== Adding annotation information ==="
    ANNOTATED_OUTPUT="${OUTPUT_PREFIX}_annotated.tsv"
    
    # Extract target sequence IDs from alignment results
    cut -f2 "$OUTPUT_FILE" | sort -u > target_ids.tmp
    
    # Extract corresponding information from annotation file
    awk 'NR==FNR {ids[$1]=1; next} $1 in ids' target_ids.tmp "$PDG_DB_ANNOT" > annotation_matches.tmp
    
    # Merge alignment results with annotations (simple example)
    join -t $'\t' -1 2 -2 1 <(sort -k2 "$OUTPUT_FILE") <(sort -k1 annotation_matches.tmp) > "$ANNOTATED_OUTPUT"
    
    if [ $? -eq 0 ]; then
        echo "✓ Annotated results saved: $ANNOTATED_OUTPUT"
    else
        echo "Note: Annotation merging step may have partial data mismatches"
    fi
    
    # Clean up temporary files
    rm -f target_ids.tmp annotation_matches.tmp
fi

# ----------------------------
# 6. Output result interpretation guide
# ----------------------------
echo ""
echo "=== Analysis completed ==="
echo "----------------------------------------"
echo "Core output files:"
echo "1. ${OUTPUT_FILE} - Raw alignment results"
if [ -f "$ANNOTATED_OUTPUT" ]; then
    echo "2. ${ANNOTATED_OUTPUT} - Annotated alignment results"
fi

echo ""
echo "Result file format description (outfmt 6):"
echo "Column 1: Query sequence ID | Column 2: Target sequence ID | Column 3: Sequence similarity"
echo "Column 4: Alignment length | Column 5: Mismatches | Column 6: Gap opens"
echo "Column 7: Query start | Column 8: Query end | Column 9: Target start"
echo "Column 10: Target end | Column 11: E-value | Column 12: Bit score"

echo ""
echo "Quick statistics of alignment hits:"
awk '{print $2}' "$OUTPUT_FILE" | sort | uniq -c | sort -rn | head -10 > top_hits.txt
echo "Top 10 most frequently matched PDGs saved to: top_hits.txt"

echo ""
echo "----------------------------------------"
echo "Recommended follow-up analyses:"
echo "1. Use PDG_DB annotation file (PDG_DB_gene_type.tsv) to interpret functional information"
echo "2. Filter high-confidence hits (E-value < 1e-10, similarity > 40%)"
echo "3. Analyze conserved functional domains with protein structure prediction"
echo "----------------------------------------"

# Usage example
echo ""
echo "Example: Filter high-quality matches"
echo "awk '\$11 < 1e-10 && \$3 > 40' ${OUTPUT_FILE} > high_confidence_hits.tsv"