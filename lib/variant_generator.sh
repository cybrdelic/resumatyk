#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"
source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/utils.sh"
source "$HOME/.local/share/resumatyk/lib/content_extractor.sh"

# Function to generate themed variant with improved content handling
generate_variant() {
    local resume_file="$1"
    local variant_name="$2"
    local theme="$3"
    local resume_base=$(basename "$resume_file" .tex)
    local variants_dir="$RESUME_DIR/variants/$resume_base"
    local max_retries=3
    local retry_count=0

    mkdir -p "$variants_dir"

    # Extract content and ensure it's captured
    log "info" "Extracting content from $resume_file"
    local content=$(extract_resume_content "$resume_file")

    if [ -z "$content" ]; then
        log "error" "Failed to extract content from $resume_file"
        return 1
    fi

    log "info" "Extracted content length: $(echo "$content" | wc -l) lines"
    format_llm_output "start"

    # Create prompt with explicit content
    local base_prompt="Create a professional LaTeX resume with this theme: '${theme}'

Requirements:
1. Use only these packages:
   \\usepackage{fontspec}
   \\usepackage{xcolor}
   \\usepackage{enumitem}
   \\usepackage{hyperref}
   \\usepackage{tikz}
   \\usepackage[margin=1cm]{geometry}

2. Font requirements:
   - Use \\setmainfont{DejaVu Serif}
   - Use \\setsansfont{DejaVu Sans} for sans-serif
   - No other font packages or commands

3. Styling:
   - Define colors using \\definecolor
   - Create custom commands for consistent styling
   - No math mode ([]) for spacing - use \\vspace instead
   - Avoid icon fonts or symbol packages

Content to style:
$content

Return ONLY the complete LaTeX code."

    while [ $retry_count -lt $max_retries ]; do
        local prompt="$base_prompt"
        format_llm_output "prompt" "$prompt"

        # Get response from AI
        local response
        response=$(curl -s https://api.anthropic.com/v1/messages \
            -H "content-type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "{
                \"model\": \"claude-3-5-sonnet-latest\",
                \"max_tokens\": 4000,
                \"messages\": [{
                    \"role\": \"user\",
                    \"content\": $(json_escape "$prompt")
                }]
            }" | jq -r '.content[0].text')

        # Extract LaTeX code
        local template
        template=$(echo "$response" | sed -n '/\\documentclass/,/\\end{document}/p')

        if [ -n "$template" ]; then
            # Save template
            log "info" "Writing generated template to $variants_dir/$variant_name.tex"
            echo "$template" >"$variants_dir/$variant_name.tex"

            # Validate and fix
            validate_and_fix_latex "$variants_dir/$variant_name.tex"

            # Try compilation
            if compile_latex "$variants_dir/$variant_name.tex"; then
                format_llm_output "success"
                clean_aux_files "$variant_name" "$variants_dir"
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    # Update prompt with error info
                    local errors=$(get_latex_errors "$variants_dir/$variant_name.tex")
                    prompt="Fix these LaTeX errors while preserving the theme:

$errors

Original content:
$content

Return the complete fixed LaTeX code."
                else
                    log "error" "Failed to generate valid LaTeX after $max_retries attempts"
                    return 1
                fi
            fi
        else
            log "error" "Failed to get valid response from AI"
            return 1
        fi
    done

    return 1
}

# Helper function to validate and fix LaTeX code
validate_and_fix_latex() {
    local tex_file="$1"
    local content=$(<"$tex_file")

    # Required elements
    if ! grep -q '\\documentclass' "$tex_file"; then
        content="\\documentclass[11pt,a4paper]{article}\n$content"
    fi

    if ! grep -q '\\usepackage{fontspec}' "$tex_file"; then
        content=$(echo "$content" | sed '/\\documentclass/a \\usepackage{fontspec}')
    fi

    if ! grep -q '\\setmainfont' "$tex_file"; then
        content=$(echo "$content" | sed '/\\usepackage{fontspec}/a \\setmainfont{DejaVu Serif}')
    fi

    # Fix common errors
    content=$(echo "$content" | sed \
        -e 's/\\\[/\\vspace{/g' \
        -e 's/\\\]/}/g' \
        -e '/\\usepackage{.*fontawesome.*}/d' \
        -e 's/\\fa[A-Za-z]*/\\textbullet/g')

    echo "$content" >"$tex_file"
}

# Helper function to get LaTeX errors
get_latex_errors() {
    local tex_file="$1"
    local log_file="${tex_file%.tex}.log"

    if [ -f "$log_file" ]; then
        grep -A1 '^!' "$log_file" | head -n 10
    else
        echo "No log file found"
    fi
}
