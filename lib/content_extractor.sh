#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"

# Declare section types as pseudo-enum
declare -ra SECTION_TYPES=(
    "CONTACT"
    "SUMMARY"
    "EDUCATION"
    "EXPERIENCE"
    "SKILLS"
    "PROJECTS"
    "OTHER"
)

# Function to validate dependencies
validate_dependencies() {
    local -ra REQUIRED_TOOLS=("pdftoppm" "tesseract" "pdftotext")
    local missing_tools=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "error" "Missing required tools: ${missing_tools[*]}"
        log "info" "Please install missing tools:"
        log "info" "sudo apt-get install poppler-utils tesseract-ocr tesseract-ocr-eng"
        return 1
    fi

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        log "error" "ANTHROPIC_API_KEY not set"
        return 1
    fi

    return 0
}

# Function to extract raw text from PDF using OCR
extract_raw_text() {
    local pdf_path="$1"
    local temp_dir
    temp_dir=$(mktemp -d)

    # Ensure temp directory cleanup
    trap 'rm -rf "$temp_dir"' EXIT

    log "info" "Converting PDF to images..."
    if ! pdftoppm -gray -r 300 "$pdf_path" "$temp_dir/page"; then
        log "error" "Failed to convert PDF to images"
        return 1
    fi

    log "info" "Performing OCR..."
    local text_output=""
    local page_count=0

    # Process each page
    for image in "$temp_dir"/page-*.pgm; do
        [[ -f "$image" ]] || continue
        page_count=$((page_count + 1))
        log "info" "Processing page $page_count..."

        local page_text
        if page_text=$(tesseract "$image" stdout -l eng --psm 6 --dpi 300 2>/dev/null); then
            text_output+="$page_text"$'\n'
        else
            log "warning" "OCR failed for page $page_count"
        fi
    done

    if [ $page_count -eq 0 ]; then
        log "error" "No pages found to process"
        return 1
    fi

    echo "$text_output"
}

# Function to clean OCR artifacts
clean_ocr_text() {
    local text="$1"
    echo "$text" |
        sed 's/[[:space:]]\+/ /g' |
        sed 's/[^[:print:]]//g' |
        sed '/^[[:space:]]*$/d' |
        sed 's/[|]/ /g'
}

# Function to structure content using Claude
structure_content() {
    local text="$1"
    local escaped_text
    escaped_text=$(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

    local prompt="Parse this resume text into clearly labeled sections.
    Organize the content into these categories: ${SECTION_TYPES[*]}.
    Return a JSON object with these section names as keys and arrays of text content as values.
    Clean up any obvious OCR errors.
    Maintain the original text's structure and bullet points.

    Resume text to parse:
    $escaped_text"

    local response
    response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d '{
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 4000,
            "messages": [{
                "role": "user",
                "content": '"$(printf '%s' "$prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"'
            }]
        }')

    # Extract just the JSON content from Claude's response
    echo "$response" | jq -r '.content[0].text' | sed -n '/^{/,/^}/p'
}

# Main extraction function
extract_resume_content() {
    local pdf_path="$1"
    local output_format="${2:-latex}"

    # Validate dependencies first
    if ! validate_dependencies; then
        return 1
    fi

    # Extract and clean text
    log "info" "Extracting text from PDF..."
    local raw_text
    if ! raw_text=$(extract_raw_text "$pdf_path"); then
        log "error" "Failed to extract text from PDF"
        return 1
    fi

    log "info" "Cleaning OCR output..."
    local cleaned_text
    cleaned_text=$(clean_ocr_text "$raw_text")

    # Structure content using Claude
    log "info" "Analyzing content structure..."
    local structured_content
    structured_content=$(structure_content "$cleaned_text")

    # Output in requested format
    case "$output_format" in
    "json")
        echo "$structured_content"
        ;;
    "latex")
        content_to_latex "$structured_content"
        ;;
    *)
        log "error" "Unknown output format: $output_format"
        return 1
        ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -lt 1 ]; then
        log "error" "Usage: $0 <pdf_path> [json|latex]"
        exit 1
    fi

    extract_resume_content "$@"
fi
