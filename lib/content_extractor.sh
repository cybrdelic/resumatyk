#!/bin/bash

source "$(dirname "$0")/config.sh"

# Function to extract content with design flexibility
extract_resume_content() {
    local file="$1"
    local temp_file=$(mktemp)

    awk '
    BEGIN {
        in_document = 0
        print "# Raw Content"
    }
    /\\begin{document}/ { in_document = 1; next }
    /\\end{document}/ { in_document = 0; next }
    in_document {
        # Extract name without formatting
        if ($0 ~ /\\name{.*}/) {
            gsub(/\\name{|}/, "")
            print "NAME:" $0
            next
        }
        # Extract email without formatting
        if ($0 ~ /\\email{.*}/) {
            gsub(/\\email{|}/, "")
            print "CONTACT:EMAIL:" $0
            next
        }
        # Extract phone without formatting
        if ($0 ~ /\\phone{.*}/) {
            gsub(/\\phone{|}/, "")
            print "CONTACT:PHONE:" $0
            next
        }
        # Extract section titles without formatting
        if ($0 ~ /\\section{.*}/) {
            gsub(/\\section{|}/, "")
            print "SECTION:" $0
            next
        }
        # Extract subsection titles without formatting
        if ($0 ~ /\\subsection{.*}/) {
            gsub(/\\subsection{|}/, "")
            print "SUBSECTION:" $0
            next
        }
        # Extract item content without formatting
        if ($0 ~ /\\item/) {
            gsub(/^[ \t]*\\item[ \t]*/, "")
            # Remove all remaining LaTeX commands
            gsub(/\\[a-zA-Z]+{[^}]*}/, "")
            gsub(/\\[a-zA-Z]+/, "")
            if (length($0) > 0) {
                print "ITEM:" $0
            }
            next
        }
        # Extract plain text without any LaTeX formatting
        if (length($0) > 0 && $0 !~ /^[ \t]*$/ && $0 !~ /^[ \t]*\\/) {
            # Remove all LaTeX commands
            gsub(/\\[a-zA-Z]+{[^}]*}/, "")
            gsub(/\\[a-zA-Z]+/, "")
            if (length($0) > 0) {
                print "TEXT:" $0
            }
        }
    }
    ' "$file" > "$temp_file"

    cat "$temp_file"
    rm "$temp_file"
}
