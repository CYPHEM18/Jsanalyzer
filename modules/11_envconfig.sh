#!/bin/bash
LABEL="[ENVCONFIG]"
TARGET="$1"
scan() {
local file="$1"
grep -niE 'process\.env\.[A-Z_]+' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(VUE_APP_|NEXT_PUBLIC_|VITE_|REACT_APP_)[A-Z_]+' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(debug|verbose|debugMode)\s*[:=]\s*(true|1)' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'featureFlag|feature_flag|FEATURE_|enableBeta|showHidden' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE '__ENV__|window\.env|window\.config|window\.appConfig' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
