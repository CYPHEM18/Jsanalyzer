#!/bin/bash
LABEL="[SUBDOMAINS]"
TARGET="$1"
scan() {
local file="$1"
grep -noP 'https?://[a-zA-Z0-9._\-]+\.[a-zA-Z]{2,}' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -noP '[a-zA-Z0-9\-]+\.(internal|local|corp|dev|staging|prod)\b' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(s3\.amazonaws|blob\.core\.windows|storage\.googleapis)' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -noP '[a-zA-Z0-9\-]+\.s3[.\-][a-zA-Z0-9\-]+\.amazonaws\.com' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(baseURL|baseUrl|API_URL|BACKEND_URL|HOST|ORIGIN)\s*[:=]' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
