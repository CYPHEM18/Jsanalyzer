#!/bin/bash
LABEL="[WEBSOCKETS]"
TARGET="$1"
scan() {
local file="$1"
grep -noP 'wss?://[^\s"'"'"']+' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'new\s+WebSocket\s*\(' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(socket\.io|sockjs)' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'socket\.(on|emit|send|connect)\s*\(' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
