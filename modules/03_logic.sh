#!/bin/bash
LABEL="[LOGIC]"
TARGET="$1"
scan() {
local file="$1"
# Role checks in actual conditionals not comments
grep -niE '^\s*if\s*\(.*\b(role|plan|tier)\b.*[=!]=.*["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# Auth guard functions
grep -niE 'function\s+[a-zA-Z]*(auth|access|permit|allow|deny|guard|protect)[a-zA-Z]*\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Hardcoded role values
grep -niE '\b(role|permission)\s*[=!]=\s*["'"'"'](admin|superuser|root|owner|moderator)["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
