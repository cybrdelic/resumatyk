#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"
source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/utils.sh"
source "$HOME/.local/share/resumatyk/lib/content_extractor.sh"


generate_variant() {
    local resume_file="$1"
    local variant_name="$2"
    local theme_preferences="$3"
    local resume_base=$(basename "$resume_file" .tex)
    local variants_dir="$RESUME_DIR/variants/$resume_base"
    local max_retries=3
    local retry_count=0

    # Join available fonts with commas for the prompt
    local fonts_list
    fonts_list=$(printf "'%s', " "${AVAILABLE_FONTS[@]}")
    fonts_list=${fonts_list%, }

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
    local content
    content=$(extract_resume_content "$pdf_file") || {
        log "error" "Failed to extract content"
        return 1
    }

    while [ $retry_count -lt $max_retries ]; do
        local prompt
        if [ $retry_count -eq 0 ]; then
            log "info" "Generating design..."
            prompt="You are an expert LaTeX designer. Create a unique resume design based on this theme description:

\"${theme_preferences}\"

AVAILABLE FONTS:
$fonts_list

These are the only fonts guaranteed to be available. Choose fonts that best match the theme's mood and style. You can mix fonts for different elements (headings, body, etc).

FONT REQUIREMENTS:
1. Use ONLY fonts from the above list
2. Set fonts using fontspec commands:
   \\setmainfont{Font Name}
   \\setsansfont{Font Name}
   \\setmonofont{Font Name}
3. You can create custom font families:
   \\newfontfamily\\headingfont{Font Name}[options]
4. Consider font features like:
   Scale=1.0
   Ligatures=TeX
   Numbers=Monospaced

Design the LaTeX template with your chosen fonts and the following requirements:
1. Must compile with XeLaTeX
2. Include all necessary packages
3. Define custom colors and styles
4. No placeholders

Content to style (organize freely):
$content

Return ONLY the complete LaTeX code."
        else
            local error_msg=$(compile_and_check "$variants_dir/$variant_name.tex")
            log "info" "Fixing compilation issues (Attempt $((retry_count + 1)))..."
            prompt="The LaTeX template has compilation errors: $error_msg

IMPORTANT: Use ONLY these fonts:
$fonts_list

Previous theme: \"${theme_preferences}\"

Content:
$content

Fix the errors while preserving the design. Return ONLY the corrected LaTeX code."
        fi

        local escaped_prompt
        escaped_prompt=$(json_escape "$prompt")

        log "debug" "Sending prompt to Claude..."
        local temp_response
        temp_response=$(mktemp)

        if ! curl -s https://api.anthropic.com/v1/messages \
            -H "content-type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d '{
                "model": "claude-3-5-sonnet-latest",
                "max_tokens": 4000,
                "messages": [{"role": "user", "content": '"$escaped_prompt"'}]
            }' >"$temp_response"; then
            log "error" "Failed to contact Claude API"
            cat "$temp_response"
            return 1
        fi

        log "info" "Extracting template..."
        local template
        template=$(jq -r '.content[0].text' "$temp_response" | sed -n '/\\documentclass/,${p;/\\end{document}/q}')

        if [ -n "$template" ]; then
            log "info" "Writing template to $variants_dir/$variant_name.tex"
            echo "$template" >"$variants_dir/$variant_name.tex"

            log "info" "Testing compilation..."
            if compile_and_check "$variants_dir/$variant_name.tex"; then
                log "success" "Created unique design variant!"
                clean_aux_files "$variant_name" "$variants_dir"
                return 0
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    log "warning" "Compilation failed. Attempting fixes..."
                else
                    log "error" "Unable to compile design after $max_retries attempts:"
                    compile_and_check "$variants_dir/$variant_name.tex"
                fi
            fi
        else
            log "error" "Failed to generate template. API response:"
            cat "$temp_response"
            return 1
        fi
    done

    return 1
}

# Export function if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f generate_variant
fi
