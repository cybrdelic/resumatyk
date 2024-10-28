#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"
source "$HOME/.local/share/resumatyk/lib/utils.sh"
source "$HOME/.local/share/resumatyk/lib/finder.sh"
source "$HOME/.local/share/resumatyk/lib/selector.sh"
source "$HOME/.local/share/resumatyk/lib/email.sh"
source "$HOME/.local/share/resumatyk/lib/variant_generator.sh"


SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Main loop
main() {
    while true; do
        selected=$(select_resume)
        [ -z "$selected" ] && { echo "No resume selected. Exiting."; exit 0; }

        tex_file="$RESUME_DIR/$selected"
        pdf_file="${tex_file%.tex}.pdf"
        dir=$(dirname "$tex_file")
        base=$(basename "$tex_file" .tex)
        variants_dir="$RESUME_DIR/variants/$base"

        # Show file status
        echo "Selected resume: $selected"
        echo "Directory: $dir"
        echo "TEX file: $([ -f "$tex_file" ] && echo "✓" || echo "✗") $tex_file"
        echo "PDF file: $([ -f "$pdf_file" ] && echo "✓" || echo "✗") $pdf_file"
        last_modified=$(stat -c %y "$tex_file" 2>/dev/null || stat -f "%Sm" "$tex_file" 2>/dev/null)
        echo "Last modified: $last_modified"

        # Action selection
        action=$(echo -e "Edit with micro\nCompile with pdflatex\nView PDF with zathura\nManage Variants\nClean auxiliary files\nSend PDF via email\nExit" | \
                 fzf --prompt="Choose Action: " --height=40% --layout=reverse)

        case "$action" in
            "Edit with micro")
                micro "$tex_file"
                ;;
            "Compile with pdflatex")
                compile_latex "$tex_file"
                ;;
            "View PDF with zathura")
                if [ ! -f "$pdf_file" ]; then
                    read -rp "PDF not found. Compile now? (y/n) " response
                    [[ "$response" =~ ^[Yy]$ ]] && compile_latex "$tex_file" || continue
                fi
                [ -f "$pdf_file" ] && zathura "$pdf_file" &
                ;;
            "Manage Variants")
                variant_action=$(echo -e "List Variants\nCreate New Variant\nEdit Variant\nView Variant PDF\nSend Variant PDF\nBack" | \
                               fzf --prompt="Choose Variant Action: " --height=40% --layout=reverse)

                case "$variant_action" in
                    "List Variants")
                        find_variants "$base" | less
                        ;;
                    "Create New Variant")
                        read -rp "Enter variant name (without .tex): " variant_name
                        if [ -n "$variant_name" ]; then
                            read -rp "Enter context/description for the theme: " context
                            [ -n "$context" ] && generate_variant "$tex_file" "$variant_name" "$context"
                        fi
                        ;;
                    "Edit Variant")
                        variant=$(select_variant "$base")
                        [ -n "$variant" ] && micro "$variants_dir/$variant"
                        ;;
                    "View Variant PDF")
                        variant=$(select_variant "$base")
                        if [ -n "$variant" ]; then
                            pdf_path="$variants_dir/${variant%.tex}.pdf"
                            if [ ! -f "$pdf_path" ]; then
                                read -rp "PDF not found. Compile now? (y/n) " response
                                [[ "$response" =~ ^[Yy]$ ]] && compile_latex "$variants_dir/$variant"
                            fi
                            [ -f "$pdf_path" ] && zathura "$pdf_path" &
                        fi
                        ;;
                    "Send Variant PDF")
                        variant=$(select_variant "$base")
                        if [ -n "$variant" ]; then
                            pdf_path="$variants_dir/${variant%.tex}.pdf"
                            if [ ! -f "$pdf_path" ]; then
                                read -rp "PDF not found. Compile now? (y/n) " response
                                [[ "$response" =~ ^[Yy]$ ]] && compile_latex "$variants_dir/$variant"
                            fi
                            [ -f "$pdf_path" ] && send_email "$pdf_path"
                        fi
                        ;;
                    "Back")
                        continue
                        ;;
                    *)
                        echo "Invalid selection."
                        ;;
                esac
                ;;
            "Send PDF via email")
                if [ ! -f "$pdf_file" ]; then
                    read -rp "PDF not found. Compile now? (y/n) " response
                    [[ "$response" =~ ^[Yy]$ ]] && compile_latex "$tex_file" || continue
                fi
                [ -f "$pdf_file" ] && send_email "$pdf_file"
                ;;
            "Clean auxiliary files")
                clean_aux_files "$base" "$dir"
                ;;
            "Exit")
                exit 0
                ;;
            *)
                echo "Invalid selection."
                ;;
        esac

        echo
        read -rp "Press Enter to continue..."
    done
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
