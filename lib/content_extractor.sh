#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"

# Function to validate dependencies
validate_dependencies() {
    local -ra REQUIRED_TOOLS=("pdftoppm" "tesseract" "pdftotext")
    local missing_tools=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if ((${#missing_tools[@]} != 0)); then
        log "error" "Missing required tools: ${missing_tools[*]}"
        log "info" "Please install missing tools:"
        log "info" "sudo apt-get install poppler-utils tesseract-ocr tesseract-ocr-eng"
        return 1
    fi

    if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
        log "error" "ANTHROPIC_API_KEY not set"
        return 1
    fi

    return 0
}

# Extract raw text from PDF using OCR
extract_raw_text() {
    local pdf_path="$1"
    local temp_dir
    temp_dir="$(mktemp -d)" || {
        log "error" "Failed to create temporary directory"
        return 1
    }

    # Ensure cleanup on exit or error
    trap 'rm -rf "${temp_dir}"' EXIT

    log "info" "Converting PDF to images..."
    if ! pdftoppm -gray -r 300 "${pdf_path}" "${temp_dir}/page"; then
        log "error" "Failed to convert PDF to images"
        return 1
    fi

    log "info" "Performing OCR..."
    local text_output=""
    local page_count=0

    while IFS= read -r -d '' image; do
        ((page_count++))
        log "info" "Processing page ${page_count}..."

        local page_text
        if page_text="$(tesseract "${image}" stdout -l eng --psm 6 --dpi 300 2>/dev/null)"; then
            text_output+="${page_text}"$'\n'
        else
            log "warning" "OCR failed for page ${page_count}"
        fi
    done < <(find "${temp_dir}" -type f -name "page-*.pgm" -print0 | sort -z)

    if ((page_count == 0)); then
        log "error" "No pages found to process"
        return 1
    fi

    printf '%s' "${text_output}"
}

# Clean OCR artifacts while preserving structure
clean_ocr_text() {
    local text="$1"
    echo "$text" | sed '
        # Remove extra whitespace
        s/[[:space:]]\+/ /g
        # Remove non-printable characters
        s/[^[:print:]]//g
        # Remove empty lines
        /^[[:space:]]*$/d
        # Remove vertical bars
        s/[|]/ /g
        # Standardize bullet points
        s/^[[:space:]]*[•∙●]/- /g
        # Format section headers
        s/\([A-Z][A-Z ]*\):/\n\1:\n/g
    '
}

# Main extraction function
extract_resume_content() {
    local pdf_path="$1"

    if ! validate_dependencies; then
        return 1
    fi

    log "info" "Extracting text from PDF..."
    local raw_text
    if ! raw_text="$(extract_raw_text "${pdf_path}")"; then
        log "error" "Failed to extract text from PDF"
        return 1
    fi

    log "info" "Cleaning OCR output..."
    local cleaned_text
    if ! cleaned_text="$(clean_ocr_text "${raw_text}")"; then
        log "error" "Failed to clean OCR text"
        return 1
    fi

    # Output the cleaned text
    printf '%s\n' "${cleaned_text}"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if (($# < 1)); then
        log "error" "Usage: $0 <pdf_path>"
        exit 1
    fi

    extract_resume_content "$@"
fi
