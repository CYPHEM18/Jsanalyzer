#!/bin/bash
LABEL="[SECRETS]"
TARGET="$1"
scan() {
local file="$1"
grep -niE '(api_key|apikey|api-key|secret|token|password|passwd|pwd)\s*[:=]' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '(aws_access|aws_secret|s3_bucket|firebase|sendgrid|stripe|twilio)' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -noP 'AKIA[0-9A-Z]{16}' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '(bearer|authorization|x-api-key)\s*[:=]' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '(private_key|client_secret|consumer_key|oauth)' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '(mongodb|mysql|postgres|redis|ftp|smtp):\/\/[^\s"'"'"']+' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -noP '[A-Za-z0-9+/]{40,}={0,2}' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
