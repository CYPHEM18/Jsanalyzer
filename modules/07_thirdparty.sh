#!/bin/bash
LABEL="[THIRDPARTY]"
TARGET="$1"
scan() {
local file="$1"
grep -noP 'https?://cdn\.[^\s"'"'"']+' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE '(gtm|analytics|hotjar|intercom|segment|mixpanel|hubspot)\.' "$file" | sed "s|^|$LABEL [INFO] $file:|"
grep -niE '__proto__|prototype\[|constructor\[' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
grep -niE '(dangerouslySetInnerHTML|innerHTML|document\.write|eval\()' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
