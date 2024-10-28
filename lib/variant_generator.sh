#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/utils.sh"
source "$HOME/.local/share/resumatyk/lib/content_extractor.sh"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Function to generate themed variant using Claude
generate_variant() {
    local resume_file="$1"
    local variant_name="$2"
    local context="$3"
    local resume_base=$(basename "$resume_file" .tex)
    local variants_dir="$RESUME_DIR/variants/$resume_base"
    local max_retries=3
    local retry_count=0

    [ -z "$ANTHROPIC_API_KEY" ] && {
        log_debug "Error: ANTHROPIC_API_KEY not set in ~/.zshrc"
        return 1
    }

    mkdir -p "$variants_dir"

    # Extract structured content
    local structured_content=$(extract_resume_content "$resume_file")

    log_debug "Extracted structured content"

    while [ $retry_count -lt $max_retries ]; do
        local prompt
        if [ $retry_count -eq 0 ]; then
            prompt=prompt="You are a creative LaTeX designer. Create a highly stylized Barbie-themed resume with modern UI/UX principles.

STYLE REQUIREMENTS:
1. Use XeLaTeX for advanced font and color support
2. Required packages to include:
   \\usepackage{tikz}
   \\usepackage{tcolorbox}
   \\usepackage[dvipsnames]{xcolor}
   \\usepackage{fontspec}
   \\usepackage{background}
   \\usepackage{geometry}

COLOR PALETTE:
- Barbie Pink (#FF69B4)
- Soft Pink (#FFB6C1)
- White (#FFFFFF)
- Accent colors as needed

DESIGN ELEMENTS TO INCLUDE:
1. Custom background pattern or design using tikz
2. Stylized headers with decorative elements
3. Creative section dividers
4. Modern typography using fontspec
5. Elegant box layouts with tcolorbox
6. Professional yet playful layout

The design should be:
- Highly visual and modern
- Professional yet creative
- Clean and readable
- Uniquely styled

Raw content to style:
$structured_content

Technical Requirements:
1. Must be a complete XeLaTeX document
2. Include all necessary packages
3. Define all custom colors and styles
4. No placeholders or partial code
5. Must compile without errors

Return ONLY the complete LaTeX code."
        else
            local error_msg=$(compile_and_check "$variants_dir/$variant_name.tex")
            prompt="The LaTeX template has these compilation errors: $error_msg

The template should maintain its creative interpretation of this theme: \"${context}\"

Original content:
$structured_content

Fix the errors while preserving the unique design. Return ONLY the corrected LaTeX code. Return the entire code with no placeholders. Think deeply about the errors and their solutions, but dont show your thought process. The final code should be clean and error-free."
        fi

        local escaped_prompt=$(json_escape "$prompt")

        log_debug "Attempt $((retry_count + 1)) of $max_retries..."

        # Call Claude API with increased tokens for more creative freedom
        local temp_response=$(mktemp)
        curl -s https://api.anthropic.com/v1/messages \
            -H "content-type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d '{
                "model": "claude-3-5-sonnet-20241022",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": '"$escaped_prompt"'
                    }
                ]
            }' > "$temp_response"

        # Extract template
        local template=$(jq -r '.content[0].text' "$temp_response" | sed -n '/\\documentclass/,${p;/\\end{document}/q}')

        if [ -n "$template" ]; then
            log_debug "Writing template to $variants_dir/$variant_name.tex"
            echo "$template" > "$variants_dir/$variant_name.tex"

            if compile_and_check "$variants_dir/$variant_name.tex"; then
                log_debug "Variant compiled successfully"
                clean_aux_files "$variant_name" "$variants_dir"
                return 0
            else
                retry_count=$((retry_count + 1))
                [ $retry_count -lt $max_retries ] && log_debug "Compilation failed. Requesting fixes from Claude..." || \
                    log_debug "Maximum retries reached. Last compilation errors:"
                compile_and_check "$variants_dir/$variant_name.tex"
            fi
        else
            log_debug "Failed to generate variant. API response:"
            cat "$temp_response"
            return 1
        fi
    done

    return 1
}
