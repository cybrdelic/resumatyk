#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print helper functions
print_status() { echo -e "${GREEN}[*]${NC} $1"; }
print_error() { echo -e "${RED}[!]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Directory containing the scripts
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LIB_DIR="$SCRIPT_DIR/lib"

# List of scripts to fix
declare -A scripts=(
    ["$LIB_DIR/utils.sh"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\""
    ["$LIB_DIR/finder.sh"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\""
    ["$LIB_DIR/selector.sh"]="source \"\$HOME/.local/share/resumatyk/lib/finder.sh\""
    ["$LIB_DIR/email.sh"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\""
    ["$LIB_DIR/variant_generator.sh"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\"
source \"\$HOME/.local/share/resumatyk/lib/utils.sh\"
source \"\$HOME/.local/share/resumatyk/lib/content_extractor.sh\""
    ["$LIB_DIR/resume_manager.sh"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\"
source \"\$HOME/.local/share/resumatyk/lib/utils.sh\"
source \"\$HOME/.local/share/resumatyk/lib/finder.sh\"
source \"\$HOME/.local/share/resumatyk/lib/selector.sh\"
source \"\$HOME/.local/share/resumatyk/lib/email.sh\"
source \"\$HOME/.local/share/resumatyk/lib/variant_generator.sh\""
    ["$SCRIPT_DIR/bin/resume"]="source \"\$HOME/.local/share/resumatyk/lib/config.sh\"
source \"\$HOME/.local/share/resumatyk/lib/utils.sh\"
source \"\$HOME/.local/share/resumatyk/lib/finder.sh\"
source \"\$HOME/.local/share/resumatyk/lib/selector.sh\"
source \"\$HOME/.local/share/resumatyk/lib/email.sh\"
source \"\$HOME/.local/share/resumatyk/lib/variant_generator.sh\"
source \"\$HOME/.local/share/resumatyk/lib/resume_manager.sh\""
)

# Function to backup file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        return 0
    fi
    return 1
}

# Function to fix source statements in a file
fix_sources() {
    local file="$1"
    local new_sources="$2"
    
    # Create backup
    if ! backup_file "$file"; then
        print_error "File not found: $file"
        return 1
    fi
    
    print_status "Fixing sources in $(basename "$file")"
    
    # Create new file with updated source statements
    {
        echo "#!/bin/bash"
        echo
        echo "$new_sources"
        echo
        # Copy rest of the file excluding the shebang and old source lines
        sed '1d' "$file" | grep -v "^source"
    } > "$file.new"
    
    # Replace original file
    mv "$file.new" "$file"
    chmod +x "$file"
    
    print_status "Updated $(basename "$file")"
}

main() {
    print_status "Starting source path fixes..."
    
    # Create backups directory
    local backup_dir="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup all original files
    for file in "${!scripts[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$backup_dir/$(basename "$file")"
        fi
    done
    
    print_status "Backed up original files to $backup_dir"
    
    # Fix each script
    for file in "${!scripts[@]}"; do
        fix_sources "$file" "${scripts[$file]}"
    done
    
    print_warning "Please verify the changes and run ./install.sh again"
    print_status "Done! Backups are stored in: $backup_dir"
}

# Run main function
main "$@"
