#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/logger.sh"

# Function to validate LaTeX code
validate_latex_code() {
    local tex_file="$1"
    local errors=0

    # Read content from file
    local content
    content=$(cat "$tex_file")

    # Check for \documentclass
    if ! grep -q '\\documentclass' <<<"$content"; then
        log "warning" "Missing \\documentclass"
        errors=$((errors + 1))
    fi

    # Check for \begin{document}
    if ! grep -q '\\begin{document}' <<<"$content"; then
        log "warning" "Missing \\begin{document}"
        errors=$((errors + 1))
    fi

    # Check for \end{document}
    if ! grep -q '\\end{document}' <<<"$content"; then
        log "warning" "Missing \\end{document}"
        errors=$((errors + 1))
    fi

    # Check for \usepackage{fontspec}
    if ! grep -q '\\usepackage{fontspec}' <<<"$content"; then
        log "warning" "Missing \\usepackage{fontspec}"
        errors=$((errors + 1))
    fi

    # Check for \setmainfont{...}
    if ! grep -q '\\setmainfont' <<<"$content"; then
        log "warning" "Missing \\setmainfont{...}"
        errors=$((errors + 1))
    fi

    # Check for unsupported fonts (e.g., Arial, Helvetica)
    if grep -E '\\(setmainfont|setsansfont|setmonofont){(Arial|Helvetica)[^}]*}' <<<"$content"; then
        log "warning" "Unsupported font detected (Arial or Helvetica)"
        errors=$((errors + 1))
    fi

    # Check for unsupported packages (e.g., fontawesome)
    if grep -q '\\usepackage{.*fontawesome.*}' <<<"$content"; then
        log "warning" "Unsupported package 'fontawesome' detected"
        errors=$((errors + 1))
    fi

    # Check for undefined control sequences like \pdfglyphtounicode
    if grep -q '\\pdfglyphtounicode' <<<"$content"; then
        log "warning" "Unsupported command '\\pdfglyphtounicode' found"
        errors=$((errors + 1))
    fi

    # Check for unbalanced braces
    local open_braces
    local close_braces
    open_braces=$(grep -o '{' <<<"$content" | wc -l)
    close_braces=$(grep -o '}' <<<"$content" | wc -l)
    if [ "$open_braces" -ne "$close_braces" ]; then
        log "warning" "Unbalanced braces detected"
        errors=$((errors + 1))
    fi

    # Return number of errors
    return $errors
}

# Function to fix LaTeX code
fix_latex_code() {
    local tex_file="$1"

    # Replace unsupported fonts with DejaVu Serif
    sed -i 's/\\setmainfont{[^}]*}/\\setmainfont{DejaVu Serif}/g' "$tex_file"
    sed -i 's/\\setsansfont{[^}]*}/\\setsansfont{DejaVu Sans}/g' "$tex_file"
    sed -i 's/\\setmonofont{[^}]*}/\\setmonofont{DejaVu Sans Mono}/g' "$tex_file"

    # Remove unsupported packages
    sed -i '/\\usepackage{.*fontawesome.*}/d' "$tex_file"

    # Remove unsupported commands
    sed -i '/\\pdfglyphtounicode/d' "$tex_file"

    # Ensure \usepackage{fontspec} is included
    if ! grep -q '\\usepackage{fontspec}' "$tex_file"; then
        sed -i '/\\usepackage/a \\usepackage{fontspec}' "$tex_file"
    fi

    # Ensure \setmainfont{DejaVu Serif} is included
    if ! grep -q '\\setmainfont{DejaVu Serif}' "$tex_file"; then
        sed -i '/\\usepackage{fontspec}/a \\setmainfont{DejaVu Serif}' "$tex_file"
    fi

    # Insert \documentclass if missing
    if ! grep -q '\\documentclass' "$tex_file"; then
        sed -i '1i\\documentclass{article}' "$tex_file"
    fi

    # Insert \begin{document} if missing
    if ! grep -q '\\begin{document}' "$tex_file"; then
        sed -i '/\\documentclass.*/a \\begin{document}' "$tex_file"
    fi

    # Insert \end{document} if missing
    if ! grep -q '\\end{document}' "$tex_file"; then
        echo '\\end{document}' >>"$tex_file"
    fi

    # Fix unbalanced braces
    local open_braces
    local close_braces
    open_braces=$(grep -o '{' "$tex_file" | wc -l)
    close_braces=$(grep -o '}' "$tex_file" | wc -l)
    while [ "$open_braces" -gt "$close_braces" ]; do
        echo '}' >>"$tex_file"
        close_braces=$((close_braces + 1))
        log "info" "Added closing brace to fix unbalanced braces"
    done
    while [ "$close_braces" -gt "$open_braces" ]; do
        sed -i '1i{' "$tex_file"
        open_braces=$((open_braces + 1))
        log "info" "Added opening brace to fix unbalanced braces"
    done
}

# Function to automatically fix LaTeX code
autofix_latex_code() {
    local tex_file="$1"
    local max_iterations=5
    local iteration=1

    while [ $iteration -le $max_iterations ]; do
        log "info" "Validation iteration $iteration"
        validate_latex_code "$tex_file"
        if [ $? -eq 0 ]; then
            log "success" "No validation errors found"
            return 0
        else
            log "info" "Attempting to fix LaTeX code"
            fix_latex_code "$tex_file"
        fi
        iteration=$((iteration + 1))
    done

    log "error" "Autofix failed after $max_iterations iterations"
    return 1
}
