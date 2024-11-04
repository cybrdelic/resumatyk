#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/finder.sh"
source "$HOME/.local/share/resumatyk/lib/logger.sh"

# Function to select resume
select_resume() {
    find_resumes | fzf \
        --prompt="Select Resume: " \
        --height=40% \
        --layout=reverse \
        --with-nth=1,2,3,4 \
        --delimiter='\t' \
        --preview 'echo {}' \
        --preview-window=up:3:wrap \
        --header="Use arrows to navigate, Enter to select" |
        cut -f1
}

# Function to select variant
select_variant() {
    local resume_base="$1"
    find_variants "$resume_base" | fzf \
        --prompt="Select Variant: " \
        --height=40% \
        --layout=reverse \
        --with-nth=1,2,3 \
        --delimiter='\t' \
        --preview "cat '$RESUME_DIR/variants/$resume_base/{}' | head -n 20" \
        --preview-window=up:3:wrap \
        --header="Use arrows to navigate, Enter to select" |
        cut -f1
}
