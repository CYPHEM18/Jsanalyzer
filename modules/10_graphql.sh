#!/bin/bash
LABEL="[GRAPHQL]"
TARGET="$1"
scan() {
local file="$1"
# GraphQL endpoints in fetch calls
grep -niE '(fetch|axios)\s*\(.*['"'"'"`]/graphql' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# gql tagged templates
grep -niE '\bgql\s*`' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [HIGH] $file:|"
# Apollo/GraphQL client usage
grep -niE '(new\s+ApolloClient|new\s+GraphQLClient|useQuery|useMutation|useLazyQuery)\s*\(' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
# Named queries and mutations
grep -niE '\b(query|mutation)\s+[A-Z][a-zA-Z]+\s*[\({]' "$file" | grep -v '^\s*//' | sed "s|^|$LABEL [MEDIUM] $file:|"
}
if [[ -f "$TARGET" ]]; then scan "$TARGET"
elif [[ -d "$TARGET" ]]; then find "$TARGET" -name "*.js" | while read -r f; do scan "$f"; done; fi
