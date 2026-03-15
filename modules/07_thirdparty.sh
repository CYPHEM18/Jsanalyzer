#!/bin/bash
LABEL="[THIRDPARTY]"
TARGET="$1"
scan() {
local file="$1"
VENDOR_COUNT=$(grep -oiE '(bootstrap|jquery|popper|lodash|moment|react|vue|angular|ember|backbone)' "$file" 2>/dev/null | wc -l)
if [[ "$VENDOR_COUNT" -gt 10 ]]; then
echo "$LABEL [INFO] $file: Vendor bundle detected ($VENDOR_COUNT hits) — skipping to avoid false positives"
return
fi
grep -niE '__proto__\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE 'prototype\['"'"'[a-zA-Z]+'"'"'\]\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '\.(innerHTML|outerHTML)\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE 'document\.write\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '\beval\s*\([^)]{3,}\)' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -noP 'https?://cdn\.[a-zA-Z0-9.\-]+/[^\s"'"'"']+\.js' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
