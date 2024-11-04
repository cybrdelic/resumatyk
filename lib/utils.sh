#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"
source "$HOME/.local/share/resumatyk/lib/config.sh"

# Function to clean auxiliary files
clean_aux_files() {
    local base="$1"
    local dir="$2"
    (
        cd "$dir" &&
            rm -f "$base.aux" "$base.log" "$base.out" "$base.toc" "$base.synctex.gz" &&
            log "cleanup" "Cleaned auxiliary files for '$base.tex'"
    )
}

# Function to escape JSON string
json_escape() {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

compile_latex() {
    local tex_file="$1"
    local dir=$(dirname "$tex_file")
    local base=$(basename "$tex_file")
    local log_file="$dir/${base%.tex}.log"

    mkdir -p "$dir"

    log "compile" "Compiling $base with XeLaTeX..."
    (cd "$dir" && xelatex -interaction=nonstopmode "$base" >/dev/null 2>&1)
    local compile_status=$?

    if [ $compile_status -ne 0 ]; then
        # Extract error messages from log
        if [ -f "$log_file" ]; then
            local error_msg=$(grep -A1 '^!' "$log_file" | sed 's/\\/\\\\/g')
            log "error" "Compilation failed: $error_msg"
        else
            log "error" "Compilation failed: No log file generated"
        fi
        return 1
    fi
    log "success" "Compilation succeeded for $base"
    return 0
}

# Enhanced compile and check function
compile_and_check() {
    local tex_file="$1"
    local dir
    dir=$(dirname "$tex_file")
    local base
    base=$(basename "$tex_file")
    local log_file="$dir/${base%.tex}.log"

    mkdir -p "$dir"

    log "compile" "Compiling $base with XeLaTeX..."
    (cd "$dir" && xelatex -interaction=nonstopmode "$base" >/dev/null 2>&1)
    local compile_status=$?

    if [ $compile_status -ne 0 ]; then
        # Extract error messages from log
        if [ -f "$log_file" ]; then
            local error_msg
            error_msg=$(grep -A1 '^!' "$log_file" | sed 's/\\/\\\\/g')
            log "error" "Compilation failed: $error_msg"
            echo "$error_msg"
        else
            log "error" "Compilation failed: No log file generated"
            echo "Compilation failed: No log file generated"
        fi
        return 1
    fi
    log "success" "Compilation succeeded for $base"
    return 0
}
