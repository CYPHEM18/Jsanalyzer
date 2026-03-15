#!/bin/bash
LABEL="[SOURCEMAPS]"
TARGET="$1"
scan() {
local file="$1"
VENDOR_COUNT=$(grep -oiE '(bootstrap|jquery|popper|lodash|moment|react|vue|angular)' "$file" 2>/dev/null | wc -l)
local maps
maps=$(grep -noP '//[#@]\s*sourceMappingURL=\S+' "$file")
if [[ -n "$maps" ]]; then
if [[ "$VENDOR_COUNT" -gt 10 ]]; then
echo "$maps" | grep -oP '(?<=sourceMappingURL=)\S+' | while read -r mapurl; do
echo "$LABEL [INFO] $file: Vendor source map: $mapurl — low priority"
done
else
echo "$maps" | sed "s|^|$LABEL [HIGH] $file:|"
echo "$maps" | grep -oP '(?<=sourceMappingURL=)\S+' | while read -r mapurl; do
echo "$LABEL [ACTION] $file: Custom source map — verify: curl -I $mapurl"
done
fi
fi
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
