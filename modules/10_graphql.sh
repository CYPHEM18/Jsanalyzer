#!/bin/bash
LABEL="[GRAPHQL]"
TARGET="$1"
scan() {
local file="$1"
grep -niE '(query|mutation|subscription)\s*[{(]' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '\/graphql|\/gql' "$file" | sed "s|^|$LABEL [HIGH] $file:|"
grep -niE '(ApolloClient|GraphQLClient|useQuery|useMutation)' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
grep -niE '__typename|IntrospectionQuery' "$file" | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
