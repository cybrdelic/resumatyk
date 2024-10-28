#!/bin/bash

# Global configuration variables
RESUME_DIR="$HOME/resumes"
EMAIL_TO="alexfigueroa.solutions@gmail.com"
EMAIL_SUBJECT="Resume Submission"
EMAIL_BODY="Please find attached my resume."
MAX_DEPTH=3

# Create necessary directories
[ ! -d "$RESUME_DIR" ] && mkdir -p "$RESUME_DIR"

# Function to log debug messages
log_debug() {
    echo "[$(date '+%H:%M:%S')] $*"
}