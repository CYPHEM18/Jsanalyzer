#!/bin/bash
LABEL="[THIRDPARTY]"
TARGET="$1"
scan() {
local file="$1"
# Prototype pollution — very specific, almost no false positives
grep -niE '__proto__\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE 'prototype\[['"'"'"]\s*[a-zA-Z]+\s*['"'"'"]\]\s*=' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
# DOM XSS sinks with user input
grep -niE '\.(innerHTML|outerHTML)\s*=' "$file" | grep -v '^\s*//' | grep -viE '(innerHTML\s*=\s*["'"'"'`]<)' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE 'document\.write\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '\beval\s*\(' "$file" | grep -v '^\s*//' | grep -v 'evaluate\|eval(' | sed "s|^|$LABEL [CRITICAL] $file:|"
# External CDN scripts
grep -noP 'https?://cdn\.[a-zA-Z0-9.\-]+/[^\s"'"'"']+\.js' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
