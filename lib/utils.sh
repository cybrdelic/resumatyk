#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Function to clean auxiliary files
clean_aux_files() {
    local base="$1"
    local dir="$2"
    (
        cd "$dir" && \
        rm -f "$base.aux" "$base.log" "$base.out" "$base.toc" "$base.synctex.gz" && \
        log_debug "Cleaned auxiliary files for '$base.tex'"
    )
}

# Function to escape JSON string
json_escape() {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

# Function to compile LaTeX file
compile_latex() {
    local tex_file="$1"
    local dir=$(dirname "$tex_file")
    local base=$(basename "$tex_file")

    (cd "$dir" && pdflatex -interaction=nonstopmode "$base")
    return $?
}

compile_and_check() {
    local tex_file="$1"
    local dir=$(dirname "$tex_file")
    local base=$(basename "$tex_file")
    local log_file="$dir/${base%.tex}.log"

    # Create the directory if it doesn't exist
    mkdir -p "$dir"

    # First try XeLaTeX for better font support
    (cd "$dir" && xelatex -interaction=nonstopmode "$base" > /dev/null 2>&1)
    local compile_status=$?

    # If XeLaTeX fails, try regular pdflatex
    if [ $compile_status -ne 0 ]; then
        (cd "$dir" && pdflatex -interaction=nonstopmode "$base" > /dev/null 2>&1)
        compile_status=$?
    fi

    # Check if log file exists before trying to read it
    if [ ! -f "$log_file" ]; then
        echo "Compilation failed: No log file generated"
        return 1
    fi

    if [ $compile_status -ne 0 ]; then
        local error_msg=$(awk '/^!/ {p=1;print;next} p&&/^l\.[0-9]/ {print;p=0}' "$log_file" | \
                        sed 's/\\/\\\\/g' | tr '\n' ' ')
        echo "$error_msg"
        return 1
    fi
    return 0
}
