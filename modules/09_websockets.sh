#!/bin/bash
LABEL="[WEBSOCKETS]"
TARGET="$1"
scan() {
local file="$1"
# Actual WebSocket constructor calls
grep -niE 'new\s+WebSocket\s*\(\s*["'"'"'`]wss?://' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# WebSocket URLs as variables
grep -noP 'wss?://[a-zA-Z0-9.\-/]+' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Socket.io connection
grep -niE '\bio\s*\(\s*["'"'"'`]|socket\.io' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# Socket event handlers
grep -niE 'socket\.(on|emit|send)\s*\(\s*["'"'"'`][a-zA-Z]' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
