#!/bin/bash
LABEL="[ENDPOINTS]"
TARGET="$1"
scan() {
local file="$1"
# Only match actual fetch/axios/http calls not comments or strings
grep -niE '^\s*(fetch|axios\.(get|post|put|delete|patch)|http\.(get|post|put|delete))\s*\(' "$file" | grep -iE '["'"'"'`]/[a-zA-Z]' | sed "s|^|$LABEL [INFO] $file:|"
# Router definitions only
grep -niE '^\s*router\.(get|post|put|delete|patch)\s*\(' "$file" | sed "s|^|$LABEL [INFO] $file:|"
# API paths that look real not just mentioned in comments
grep -niE '["'"'"'`]/api/[a-zA-Z0-9_\-/]+["'"'"'`]' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [INFO] $file:|"
# High value — admin/internal paths
grep -niE '["'"'"'`]/(admin|internal|debug|staging|dev|beta)/[a-zA-Z]' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
