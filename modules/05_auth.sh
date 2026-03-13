#!/bin/bash
LABEL="[AUTH]"
TARGET="$1"
scan() {
local file="$1"
grep -niE '(role|permission|privilege|scope|claim)\s*[=!<>]+' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(isAdmin|isOwner|isAuthenticated|isAuthorized|canEdit|canDelete)' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'localStorage\.(get|set)Item\s*\(' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE 'sessionStorage\.(get|set)Item\s*\(' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE 'jwt\.(decode|verify|sign)\s*\(' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'token\.split\s*\(' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE 'window\.__APP_STATE__|window\.__INITIAL_STATE__' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(bearer|authorization)\s*[:=]\s*.*token' "$file" | sed "s|^|$LABEL [CRITICAL] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
