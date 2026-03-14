#!/bin/bash
LABEL="[ENVCONFIG]"
TARGET="$1"
scan() {
local file="$1"
# process.env access — filter out NODE_ENV comparisons which are normal
grep -niE 'process\.env\.[A-Z_]{3,}' "$file" | grep -v '^\s*//' | grep -viE 'process\.env\.NODE_ENV\s*[!=]==\s*["'"'"'](development|test)["'"'"']' | sed "s|^|$LABEL [HIGH] $file:|"
# Framework env vars assigned
grep -niE '(REACT_APP_|VUE_APP_|NEXT_PUBLIC_|VITE_)[A-Z_]+=\s*["'"'"'][^'"'"'"]{4,}["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Debug mode enabled
grep -niE '(debugMode|verbose|debug)\s*[:=]\s*true' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Feature flags enabled
grep -niE '(enableBeta|showHidden|featureFlag)\s*[:=]\s*true' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# window config objects
grep -niE 'window\.(appConfig|env|config)\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
