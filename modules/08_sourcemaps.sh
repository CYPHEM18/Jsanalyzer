#!/bin/bash
LABEL="[SOURCEMAPS]"
TARGET="$1"
scan() {
local file="$1"
local maps
maps=$(grep -noP '//# sourceMappingURL=.*' "$file")
if [[ -n "$maps" ]]; then
echo "$maps" | sed "s|^|$LABEL [HIGH] $file:|"
echo "$maps" | grep -oP '(?<=sourceMappingURL=)\S+' | while read -r mapurl; do
echo "$LABEL [ACTION] Source map found: $mapurl — fetch with: curl $mapurl -o sourcemap.json"
done
fi
grep -niE '\.map\b' "$file" | sed "s|^|$LABEL [INFO] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
