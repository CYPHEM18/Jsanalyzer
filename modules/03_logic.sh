#!/bin/bash
LABEL="[LOGIC]"
TARGET="$1"
scan() {
local file="$1"
grep -niE '(if|switch|case|else)\s*.*\b(role|plan|tier|status|flag|type)\b' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE '(validate|verify|check|enforce|assert|require)\s*\(' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE '(limit|quota|threshold|max|min|allowed|restrict)' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE 'function\s+[a-zA-Z]*(auth|access|permit|allow|deny|guard)[a-zA-Z]*\s*\(' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
