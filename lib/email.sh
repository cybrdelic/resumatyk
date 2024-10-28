#!/bin/bash

source "$HOME/.local/share/resumatyk/lib/config.sh"


SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Function to send email
send_email() {
    local pdf_file="$1"

    [ ! -f "$pdf_file" ] && { log_debug "PDF file not found: $pdf_file"; return 1; }
    [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] && {
        log_debug "Error: Email credentials not set!"
        log_debug "Please ensure SMTP_USER and SMTP_PASS are set in your ~/.zshrc"
        return 1
    }

    local TEMP_EMAIL=$(mktemp)
    local BOUNDARY="------------$(date +%Y%m%d%H%M%S)"

    {
        echo -e "From: $SMTP_USER\r"
        echo -e "To: $EMAIL_TO\r"
        echo -e "Subject: $EMAIL_SUBJECT\r"
        echo -e "MIME-Version: 1.0\r"
        echo -e "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\"\r"
        echo -e "\r"
        echo -e "--$BOUNDARY\r"
        echo -e "Content-Type: text/plain; charset=UTF-8\r"
        echo -e "Content-Transfer-Encoding: 7bit\r"
        echo -e "\r"
        echo -e "$EMAIL_BODY\r"
        echo -e "\r"
        echo -e "--$BOUNDARY\r"
        echo -e "Content-Type: application/pdf\r"
        echo -e "Content-Disposition: attachment; filename=\"$(basename "$pdf_file")\"\r"
        echo -e "Content-Transfer-Encoding: base64\r"
        echo -e "\r"
        base64 "$pdf_file" | fold -w 76 | sed 's/$/\r/'
        echo -e "\r"
        echo -e "--$BOUNDARY--\r"
        echo -e "\r.\r"
    } > "$TEMP_EMAIL"

    curl --url "smtps://smtp.gmail.com:465" \
        --ssl-reqd \
        --mail-from "$SMTP_USER" \
        --mail-rcpt "$EMAIL_TO" \
        --user "$SMTP_USER:$SMTP_PASS" \
        --upload-file "$TEMP_EMAIL" \
        --silent \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 5 \
        --retry-max-time 60 && {
        log_debug "Resume sent successfully!"
        rm "$TEMP_EMAIL"
        return 0
    } || {
        log_debug "Failed to send email. Error code: $?"
        log_debug "Failed email content preserved at: $TEMP_EMAIL"
        return 1
    }
}
