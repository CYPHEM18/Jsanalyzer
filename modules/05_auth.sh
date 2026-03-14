#!/bin/bash
LABEL="[AUTH]"
TARGET="$1"
scan() {
local file="$1"
# localStorage storing sensitive keys
grep -niE 'localStorage\.setItem\s*\(\s*["'"'"'][^'"'"'"]*?(token|auth|session|key|secret)[^'"'"'"]*?["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'localStorage\.getItem\s*\(\s*["'"'"'][^'"'"'"]*?(token|auth|session|key|secret)[^'"'"'"]*?["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# JWT operations
grep -niE 'jwt\.(decode|verify|sign)\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# JWT decode manually via atob and split
grep -niE 'atob\s*\(.*split\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Client side role/admin checks
grep -niE '\b(isAdmin|isOwner|isSuperUser|isAuthenticated|canDelete|canEdit)\b\s*[=!]' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# App state with sensitive data
grep -niE 'window\.__APP_STATE__|window\.__INITIAL_STATE__' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Weak JWT secret
grep -niE 'jwt\.(sign|verify)\s*\(.*["'"'"'][a-zA-Z0-9]{4,20}["'"'"']' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [CRITICAL] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
