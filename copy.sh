#!/bin/bash

# Function to check if a file is likely a build script
is_build_script() {
    local filename="$1"
    local content="$2"
    local lowercase_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]')

    # Check filename for build-related terms
    if [[ "$lowercase_name" =~ (build|compile|install|setup|configure|make|cmake|package|deploy) ]]; then
        return 0
    fi

    # Check content for common build tool commands
    if grep -q -E "(make |cmake|npm |yarn |gradle|mvn |docker build|cargo build|pip install)" <<< "$content"; then
        return 0
    fi

    return 1
}

# Function to check if a script has meaningful content
is_meaningful_script() {
    local content="$1"
    local meaningful_lines=0

    # Count lines with meaningful bash constructs
    if grep -q -E "(function|if.*then|for.*in|while|case|\$\{.*\}|\$\(\(.*\)\)|\|\||&&)" <<< "$content"; then
        return 0
    fi

    # Count non-empty, non-comment lines
    meaningful_lines=$(echo "$content" | grep -v '^#' | grep -v '^[[:space:]]*$' | wc -l)

    # Return success if we have more than 5 meaningful lines
    [[ $meaningful_lines -gt 5 ]]
    return $?
}

# Create temporary file for output
tmp_file=$(mktemp)

# Find and process shell scripts
while IFS= read -r -d '' file; do
    # Check if file is executable or has .sh/.bash extension
    if [[ -x "$file" || "$file" =~ \.(sh|bash)$ ]]; then
        # Check if file starts with shebang
        if head -n1 "$file" | grep -q '^#!.*sh'; then
            content=$(cat "$file")

            # Skip build scripts
            if is_build_script "$(basename "$file")" "$content"; then
                continue
            fi

            # Only include meaningful scripts
            if is_meaningful_script "$content"; then
                echo -e "\n### ${file#./} ###" >> "$tmp_file"
                echo "$content" >> "$tmp_file"
            fi
        fi
    fi
done < <(find . -type f -print0)

# Copy to clipboard using available clipboard command
if command -v pbcopy >/dev/null 2>&1; then  # macOS
    cat "$tmp_file" | pbcopy
elif command -v xclip >/dev/null 2>&1; then  # Linux with X11
    cat "$tmp_file" | xclip -selection clipboard
elif command -v clip.exe >/dev/null 2>&1; then  # Windows
    cat "$tmp_file" | clip.exe
else
    echo "No clipboard command found. Output saved to: $tmp_file"
    exit 1
fi

# Clean up
rm "$tmp_file"

echo "Relevant script contents have been copied to clipboard!"
