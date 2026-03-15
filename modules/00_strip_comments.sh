#!/bin/bash
INPUT="$1"
TEMP=$(mktemp "$TMPDIR/jsanalyzer_stripped_XXXXXX.js")
sed 's|//[^"'"'"']*$||g' "$INPUT" | \
sed '/\/\*/,/\*\//d' > "$TEMP"
echo "$TEMP"
