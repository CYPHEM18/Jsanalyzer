#!/bin/bash
LABEL="[ENDPOINTS]"
TARGET="$1"
scan() {
local file="$1"
grep -noP '(\/api\/[a-zA-Z0-9_\-\/]+)' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE '(fetch|axios|http|xhr|ajax)\s*\(["'"'"'`]\/[a-z]' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE '(get|post|put|delete|patch)\s*\(["'"'"'`]\/[a-z]' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE 'router\.(get|post|put|delete)\s*\(["'"'"'`]' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE '(admin|internal|debug|staging|test|dev|beta)\/[a-z]' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
