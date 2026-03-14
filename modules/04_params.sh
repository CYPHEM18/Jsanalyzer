#!/bin/bash
LABEL="[PARAMS]"
TARGET="$1"
scan() {
local file="$1"
# Query params in actual fetch/axios calls
grep -niE '(fetch|axios)\s*\(.*\?[a-zA-Z0-9_]+=\S+' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [INFO] $file:|"
# req.body/query/params access
grep -niE 'req\.(body|query|params)\.[a-zA-Z_][a-zA-Z0-9_]*' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# formData.append with real field names
grep -niE 'formData\.append\s*\(\s*["'"'"'][a-zA-Z_][a-zA-Z0-9_]*["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [INFO] $file:|"
# JSON body keys in fetch calls
grep -niE 'body\s*:\s*JSON\.stringify\s*\(\s*\{' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [INFO] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
