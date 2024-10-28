#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"


SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Function to find and format resume files
find_resumes() {
    find "$RESUME_DIR" -maxdepth "$MAX_DEPTH" -type f -name "*.tex" -not -path "*/variants/*" -printf "%P\t%T@\n" | \
    while IFS=$'\t' read -r file timestamp; do
        local dir=$(dirname "$file")
        local base=$(basename "$file" .tex)
        local pdf_path="$RESUME_DIR/$dir/$base.pdf"
        local variants_dir="$RESUME_DIR/$dir/variants/$base"
        local variant_count=$([ -d "$variants_dir" ] && find "$variants_dir" -name "*.tex" | wc -l || echo "0")
        local status=$([ -f "$pdf_path" ] && echo "[PDF ✓]" || echo "[No PDF]")
        local date_display=$(date -d "@${timestamp%.*}" "+%Y-%m-%d %H:%M:%S")
        echo -e "$file\t$status\t$variant_count variants\t$date_display"
    done | sort -r
}

# Function to find and format variants of a specific resume
find_variants() {
    local resume_base="$1"
    local variants_dir="$RESUME_DIR/variants/$resume_base"

    [ ! -d "$variants_dir" ] && return

    find "$variants_dir" -type f -name "*.tex" -printf "%P\t%T@\n" | \
    while IFS=$'\t' read -r file timestamp; do
        local pdf_path="$variants_dir/${file%.tex}.pdf"
        local status=$([ -f "$pdf_path" ] && echo "[PDF ✓]" || echo "[No PDF]")
        local date_display=$(date -d "@${timestamp%.*}" "+%Y-%m-%d %H:%M:%S")
        echo -e "$file\t$status\t$date_display"
    done | sort -r
}
