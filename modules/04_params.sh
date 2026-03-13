#!/bin/bash
LABEL="[PARAMS]"
TARGET="$1"
scan() {
local file="$1"
grep -noP '(?<=\?)[a-zA-Z0-9_]+=' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE 'params\.[a-zA-Z_]+' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE 'body\.[a-zA-Z_]+' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE 'req\.(query|body|params)\.[a-zA-Z_]+' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE '(formData|FormData|append)\s*\(' "$file" | sed "s|^|$LABEL [INFO] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
