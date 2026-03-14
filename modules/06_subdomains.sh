#!/bin/bash
LABEL="[SUBDOMAINS]"
TARGET="$1"
scan() {
local file="$1"
# Internal hostnames — high confidence
grep -noP '[a-zA-Z0-9\-]+\.(internal|local|corp)\b' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# S3 buckets — very specific
grep -noP '[a-zA-Z0-9\-]+\.s3[.\-][a-zA-Z0-9\-]+\.amazonaws\.com' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
# Dev/staging URLs assigned to variables
grep -niE '(baseURL|baseUrl|API_URL|BACKEND_URL|HOST)\s*[:=]\s*["'"'"']https?://' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# Staging/dev subdomains in strings
grep -noP 'https?://[a-zA-Z0-9\-]*(dev|staging|qa|uat|test)[a-zA-Z0-9\-]*\.[a-zA-Z0-9.\-]+' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Cloud storage
grep -niE '(s3\.amazonaws|blob\.core\.windows|storage\.googleapis)\.' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
