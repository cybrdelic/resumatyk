#!/bin/bash
# lib/variant_generator.sh

source "$HOME/.local/share/resumatyk/lib/logger.sh"
source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/utils.sh"
source "$HOME/.local/share/resumatyk/lib/content_extractor.sh"

# Theme configuration
declare -rA THEME_CONFIG=(
    ["MIN_LENGTH"]="10"
    ["MAX_LENGTH"]="200"
    ["REQUIRED_KEYWORDS"]="style design layout color theme look feel"
)

# Function to generate themed variant using Claude
generate_variant() {
    local resume_file="$1"
    local variant_name="$2"
    local theme="$3"
    local resume_base=$(basename "$resume_file" .tex)
    local variants_dir="$RESUME_DIR/variants/$resume_base"
    local max_retries=3
    local retry_count=0

    [ -z "$ANTHROPIC_API_KEY" ] && {
        log "error" "ANTHROPIC_API_KEY not set"
        return 1
    }

    mkdir -p "$variants_dir"

    # Generate or update PDF if needed
    local pdf_file="${resume_file%.tex}.pdf"
    if [ ! -f "$pdf_file" ] || [ "$resume_file" -nt "$pdf_file" ]; then
        log "info" "Generating PDF from LaTeX..."
        compile_latex "$resume_file" || {
            log "error" "Failed to compile source LaTeX file"
            return 1
        }
    fi

    # Extract structured content
    log "info" "Extracting content from PDF..."
    local structured_content
    structured_content=$(extract_resume_content "$pdf_file" "json") || {
        log "error" "Failed to extract content"
        return 1
    }

    while [ $retry_count -lt $max_retries ]; do
        local prompt
        if [ $retry_count -eq 0 ]; then
            prompt="You are a creative LaTeX designer. Create a highly distinctive resume design based on this theme:

\"${theme}\"

Requirements:
1. Use XeLaTeX for advanced font and color support
2. Required packages:
   \\usepackage{fontspec}
   \\usepackage{xcolor}
   \\usepackage{tikz}
   \\usepackage{enumitem}
   \\usepackage[margin=1cm]{geometry}

3. Font requirements:
   - Use \\setmainfont{DejaVu Serif}
   - Use \\setsansfont{DejaVu Sans}

4. Design elements:
   - Create a unique header/layout
   - Use consistent styling
   - Maintain professional appearance
   - Include section dividers
   - Create custom commands for styling

Content to style (in JSON format):
$structured_content

Return ONLY the complete LaTeX code."
        else
            local error_msg=$(compile_and_check "$variants_dir/$variant_name.tex")
            prompt="Fix these LaTeX errors while preserving the theme:

$error_msg

Content to preserve:
$structured_content

Return ONLY the corrected LaTeX code."
        fi

        local escaped_prompt
        escaped_prompt=$(json_escape "$prompt")

        log "debug" "Generation attempt $((retry_count + 1)) of $max_retries..."

        # Call Claude API
        local response
        response=$(curl -s https://api.anthropic.com/v1/messages \
            -H "content-type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d '{
                "model": "claude-3-5-sonnet-latest",
                "max_tokens": 4000,
                "messages": [{"role": "user", "content": '"$escaped_prompt"'}]
            }')

        # Extract LaTeX template
        local template
        template=$(echo "$response" | jq -r '.content[0].text' | sed -n '/\\documentclass/,/\\end{document}/p')

        if [ -n "$template" ]; then
            log "info" "Writing template to $variants_dir/$variant_name.tex"
            echo "$template" >"$variants_dir/$variant_name.tex"

            if compile_latex "$variants_dir/$variant_name.tex"; then
                log "success" "Variant generated and compiled successfully"
                clean_aux_files "$variant_name" "$variants_dir"
                return 0
            else
                retry_count=$((retry_count + 1))
                [ $retry_count -lt $max_retries ] && log "warning" "Compilation failed. Requesting fixes..."
            fi
        else
            log "error" "Failed to generate valid LaTeX code"
            return 1
        fi
    done

    log "error" "Failed to generate variant after $max_retries attempts"
    return 1
}

# Function to validate theme description
validate_theme() {
    local theme="$1"

    if [ ${#theme} -lt "${THEME_CONFIG[MIN_LENGTH]}" ]; then
        log "error" "Theme description too short (minimum ${THEME_CONFIG[MIN_LENGTH]} characters)"
        return 1
    fi

    if [ ${#theme} -gt "${THEME_CONFIG[MAX_LENGTH]}" ]; then
        log "error" "Theme description too long (maximum ${THEME_CONFIG[MAX_LENGTH]} characters)"
        return 1
    fi

    local has_keywords=false
    for keyword in ${THEME_CONFIG[REQUIRED_KEYWORDS]}; do
        if echo "$theme" | grep -qi "$keyword"; then
            has_keywords=true
            break
        fi
    done

    if [ "$has_keywords" = false ]; then
        log "warning" "Theme description should include design-related terms"
        read -rp "Continue anyway? (y/N) " response
        [[ "$response" =~ ^[Yy]$ ]] || return 1
    fi

    return 0
}

# Only export if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f generate_variant
    export -f validate_theme
fi
