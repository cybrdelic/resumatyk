#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/logger.sh"

# Function to extract resume content while preserving structure
extract_resume_content() {
    local file="$1"
    local temp_file=$(mktemp)

    # First pass: Extract content between \begin{document} and \end{document}
    sed -n '/\\begin{document}/,/\\end{document}/p' "$file" >"$temp_file"

    # Process and clean up the content
    cat "$temp_file" |
        # Remove LaTeX comments
        sed 's/%.*$//' |
        # Preserve important structural elements
        sed -e 's/\\section{/\nsection\n/g' \
            -e 's/\\subsection{/\nsubsection\n/g' \
            -e 's/\\begin{itemize}/\nitemize\n/g' \
            -e 's/\\begin{center}/\ncenter\n/g' \
            -e 's/\\end{itemize}/itemize\n/g' \
            -e 's/\\end{center}/center\n/g' \
            -e 's/\\item */\nitem /' |
        # Convert common LaTeX commands
        sed -e 's/\\textbf{\([^}]*\)}/\1/g' \
            -e 's/\\textit{\([^}]*\)}/\1/g' \
            -e 's/\\emph{\([^}]*\)}/\1/g' \
            -e 's/\\href{[^}]*}{\([^}]*\)}/\1/g' \
            -e 's/\\url{\([^}]*\)}/\1/g' \
            -e 's/\\vspace{[^}]*}//' |
        # Handle special spacing commands
        sed -e 's/\\smallskip//' \
            -e 's/\\medskip//' \
            -e 's/\\bigskip//' \
            -e 's/\\quad/ /g' \
            -e 's/\\,/ /g' |
        # Remove remaining LaTeX commands and braces
        sed -e 's/\\[[:alpha:]]*{//g' \
            -e 's/}//g' \
            -e 's/\\[[:alpha:]]*\[[^]]*\]//g' |
        # Clean up whitespace
        sed -e 's/^[ \t]*//g' \
            -e 's/[ \t]*$//g' \
            -e '/^$/d' |
        # Preserve special markers
        sed -e 's/neo_accent|/neo_accent|/g' |
        # Final cleanup - remove unwanted lines
        grep -v '^\\' |
        grep -v '^document$' |
        grep -v '^begin{.*}$' |
        grep -v '^end{.*}$' |
        grep -v '^\s*$'

    rm "$temp_file"
}

# Test if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" ]; then
        if [ -f "$1" ]; then
            log "info" "Extracting content from $1"
            extract_resume_content "$1"
        else
            log "error" "File not found: $1"
            exit 1
        fi
    else
        log "error" "Usage: $0 <tex-file>"
        exit 1
    fi
fi
