#!/bin/bash
LABEL="[SOURCEMAPS]"
TARGET="$1"
scan() {
local file="$1"
local maps
maps=$(grep -noP '//[#@]\s*sourceMappingURL=\S+' "$file")
if [[ -n "$maps" ]]; then
echo "$maps" | sed "s|^|$LABEL [HIGH] $file:|"
echo "$maps" | grep -oP '(?<=sourceMappingURL=)\S+' | while read -r mapurl; do
echo "$LABEL [ACTION] Fetch map: curl $mapurl -o sourcemap.json"
done
fi
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
