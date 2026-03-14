#!/bin/bash
LABEL="[SECRETS]"
TARGET="$1"
scan() {
local file="$1"
# Must be assigned a value not just mentioned
grep -niE '(api_key|apikey|api-key|secret_key|secretkey)\s*[:=]\s*["'"'"'][^'"'"'"{][^'"'"'"]{6,}["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
# Password assigned a real value not a placeholder
grep -niE '(password|passwd|pwd)\s*[:=]\s*["'"'"'][^'"'"'"{][^'"'"'"]{4,}["'"'"']' "$file" | grep -v '^\s*//' | grep -viE '(placeholder|example|your_|enter|sample|test|dummy|label|hint|message)' | sed "s|^|$LABEL [CRITICAL] $file:|"
# AWS key — very specific pattern, almost no false positives
grep -noP 'AKIA[0-9A-Z]{16}' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
# Bearer token with actual value
grep -niE 'authorization\s*[:=]\s*["'"'"']Bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
# Connection strings with credentials
grep -niE '(mongodb|mysql|postgres|redis|ftp|smtp):\/\/[^'"'"'"\s]{4,}:[^'"'"'"\s]{4,}@' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
# Stripe/sendgrid/twilio keys assigned
grep -niE '(stripe|sendgrid|twilio)\s*[:=]\s*["'"'"'][a-zA-Z0-9_\-]{20,}["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
# Firebase assigned
grep -niE 'firebase\s*[:=]\s*["'"'"'][^'"'"'"]{10,}["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
