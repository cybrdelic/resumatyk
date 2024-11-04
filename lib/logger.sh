#!/bin/bash

# Rich terminal output colors and styles
declare -A LOG_COLORS=(
    ["reset"]="\033[0m"
    ["bold"]="\033[1m"
    ["dim"]="\033[2m"
    ["italic"]="\033[3m"
    ["underline"]="\033[4m"
    ["black"]="\033[30m"
    ["red"]="\033[31m"
    ["green"]="\033[32m"
    ["yellow"]="\033[33m"
    ["blue"]="\033[34m"
    ["magenta"]="\033[35m"
    ["cyan"]="\033[36m"
    ["white"]="\033[37m"
    ["bg_black"]="\033[40m"
    ["bg_red"]="\033[41m"
    ["bg_green"]="\033[42m"
    ["bg_yellow"]="\033[43m"
    ["bg_blue"]="\033[44m"
    ["bg_magenta"]="\033[45m"
    ["bg_cyan"]="\033[46m"
    ["bg_white"]="\033[47m"
)

# Icons for different message types
declare -A LOG_ICONS=(
    ["info"]="ℹ️ "
    ["success"]="✅"
    ["warning"]="⚠️ "
    ["error"]="❌"
    ["debug"]="🔍"
    ["llm"]="🤖"
    ["compile"]="📄"
    ["email"]="📧"
    ["cleanup"]="🧹"
)

# Function to get terminal width
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

# Function to create a divider line
make_divider() {
    local char="${1:-─}"
    local width=$(get_term_width)
    printf '%*s\n' "$width" | tr ' ' "$char"
}

# Enhanced logging function
log() {
    local type="$1"
    local message="$2"
    local timestamp="$(date '+%H:%M:%S')"
    local icon="${LOG_ICONS[$type]:-}"
    local color="${LOG_COLORS[cyan]}"
    local prefix_color="${LOG_COLORS[dim]}"

    case "$type" in
    "success") color="${LOG_COLORS[green]}" ;;
    "warning") color="${LOG_COLORS[yellow]}" ;;
    "error") color="${LOG_COLORS[red]}" ;;
    "debug") color="${LOG_COLORS[magenta]}" ;;
    "llm") color="${LOG_COLORS[blue]}" ;;
    "compile") color="${LOG_COLORS[cyan]}" ;;
    "email") color="${LOG_COLORS[cyan]}" ;;
    "cleanup") color="${LOG_COLORS[cyan]}" ;;
    esac

    printf "${prefix_color}[%s]${LOG_COLORS[reset]} ${color}%s${LOG_COLORS[reset]} %s\n" \
        "$timestamp" "$icon" "$message"
}

# Function to format LLM interaction output
format_llm_output() {
    local stage="$1"
    local content="$2"

    case "$stage" in
    "start")
        make_divider
        log "llm" "Starting AI Generation..."
        ;;
    "prompt")
        log "llm" "Prompt sent to AI:"
        echo
        printf "${LOG_COLORS[dim]}%s${LOG_COLORS[reset]}\n" "$content"
        ;;
    "response")
        log "llm" "AI Response received:"
        echo
        printf "${LOG_COLORS[cyan]}%s${LOG_COLORS[reset]}\n" "$content"
        ;;
    "success")
        log "success" "Template generated and compiled successfully!"
        make_divider
        ;;
    "error")
        log "error" "Error during AI Generation: $content"
        ;;
    "compile")
        log "compile" "Compiling LaTeX document..."
        ;;
    esac
}

# Function to show a spinner during long operations
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    printf " "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "%c" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    printf " \b\b"
}

# Function to time an operation
time_operation() {
    local start=$(date +%s.%N)
    "$@"
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc)
    printf "${LOG_COLORS[dim]}(took %.2f seconds)${LOG_COLORS[reset]}\n" "$duration"
}
