#!/bin/bash
VERSION="1.1"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
TARGET_FILE=""
TARGET_DIR=""
TARGET_URL=""
TARGET_LIST=""
OUTPUT_FILE=""
JSON_MODE=false
RUN_ALL=false
SELECTED_MODULES=()
TEMP_JS=""
declare -A MODULE_COUNTS
TOTAL_FINDINGS=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
declare -A MODULE_MAP
MODULE_MAP=([1]="01_endpoints.sh" [2]="02_secrets.sh" [3]="03_logic.sh" [4]="04_params.sh" [5]="05_auth.sh" [6]="06_subdomains.sh" [7]="07_thirdparty.sh" [8]="08_sourcemaps.sh" [9]="09_websockets.sh" [10]="10_graphql.sh" [11]="11_envconfig.sh")
declare -A MODULE_NAMES
MODULE_NAMES=([1]="Hidden API Endpoints & Routes" [2]="Sensitive Data / Hardcoded Secrets" [3]="Business Logic Mapping" [4]="Parameter Discovery" [5]="Auth & Authorization Logic" [6]="Subdomain & Internal Hosts" [7]="Third-Party & Supply Chain" [8]="Source Map References" [9]="WebSocket Endpoints" [10]="GraphQL Detection" [11]="Environment & Config Leakage")
banner() {
echo -e "${CYAN}"
echo " jsanalyzer v${VERSION} — JavaScript Analyzer for Pentesters"
echo " by Cyphem | github.com/CYPHEM18/Jsanalyzer"
echo -e "${NC}"
}
usage() {
echo -e "${WHITE}USAGE${NC}"
echo "  $0 [input] [scan options] [output options]"
echo ""
echo -e "${WHITE}INPUT${NC}"
echo "  -f FILE       Single JS file"
echo "  -d DIR        Directory of JS files"
echo "  -u URL        Remote JS file (auto-downloaded)"
echo "  -l FILE       Text file containing list of JS URLs"
echo ""
echo -e "${WHITE}SCAN OPTIONS${NC}"
echo "  --all           Run all 11 modules"
echo "  --category N    Comma-separated e.g. --category 1,3,5"
echo "  --endpoints     Module  1 - Hidden API Endpoints"
echo "  --secrets       Module  2 - Hardcoded Secrets"
echo "  --logic         Module  3 - Business Logic"
echo "  --params        Module  4 - Parameter Discovery"
echo "  --auth          Module  5 - Auth & Authorization"
echo "  --subdomains    Module  6 - Subdomains & Internal Hosts"
echo "  --thirdparty    Module  7 - Third-Party & Supply Chain"
echo "  --sourcemaps    Module  8 - Source Map References"
echo "  --websockets    Module  9 - WebSocket Endpoints"
echo "  --graphql       Module 10 - GraphQL Detection"
echo "  --envconfig     Module 11 - Environment & Config Leakage"
echo ""
echo -e "${WHITE}OUTPUT${NC}"
echo "  -o FILE       Save results to file"
echo "  --json        Output as JSON"
echo ""
echo -e "${WHITE}EXAMPLES${NC}"
echo "  $0 -f app.js --all"
echo "  $0 -d ./js_files/ --secrets --auth"
echo "  $0 -u https://target.com/app.bundle.js --all -o findings.txt"
echo "  $0 -l js_urls.txt --all -o findings.txt"
echo "  $0 -f app.js --category 1,5,11"
echo ""
echo -e "${WHITE}IMPORTANT${NC}"
echo "  All findings should be manually verified before reporting."
echo "  False positives are expected — use this as a triage tool."
echo "  For authorized testing only."
}
colorize_line() {
local line="$1"
if echo "$line" | grep -q '\[CRITICAL\]'; then echo -e "${RED}$line${NC}"
elif echo "$line" | grep -q '\[HIGH\]'; then echo -e "${YELLOW}$line${NC}"
elif echo "$line" | grep -q '\[MEDIUM\]'; then echo -e "${MAGENTA}$line${NC}"
elif echo "$line" | grep -q '\[ACTION\]'; then echo -e "${CYAN}$line${NC}"
else echo -e "${DIM}$line${NC}"; fi
}
count_severity() {
local line="$1"
if echo "$line" | grep -q '\[CRITICAL\]'; then ((CRITICAL_COUNT++)); fi
if echo "$line" | grep -q '\[HIGH\]'; then ((HIGH_COUNT++)); fi
if echo "$line" | grep -q '\[MEDIUM\]'; then ((MEDIUM_COUNT++)); fi
if echo "$line" | grep -q '\[INFO\]'; then ((INFO_COUNT++)); fi
((TOTAL_FINDINGS++))
}
run_module() {
local num="$1"
local target="$2"
local module="${MODULE_MAP[$num]}"
local name="${MODULE_NAMES[$num]}"
local module_path="$MODULES_DIR/$module"
if [[ ! -f "$module_path" ]]; then echo -e "${RED}[!] Module not found: $module_path${NC}"; return; fi
echo -e "\n${CYAN}[ Module $num ] $name${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
local results
results=$(bash "$module_path" "$target" 2>/dev/null | sort -u)
if [[ -z "$results" ]]; then
echo -e "${DIM}  No findings.${NC}"
MODULE_COUNTS[$num]=0
else
local count=0
while IFS= read -r line; do
[[ -z "$line" ]] && continue
colorize_line "  $line"
count_severity "$line"
((count++))
if [[ -n "$OUTPUT_FILE" ]] && [[ "$JSON_MODE" == false ]]; then echo "$line" >> "$OUTPUT_FILE"; fi
done <<< "$results"
MODULE_COUNTS[$num]=$count
echo -e "${DIM}  -> $count finding(s)${NC}"
fi
}
run_all_modules() {
local target="$1"
for num in "${SELECTED_MODULES[@]}"; do
run_module "$num" "$target"
done
}
print_summary() {
echo ""
echo -e "${WHITE}=============================${NC}"
echo -e "${WHITE}        SCAN SUMMARY         ${NC}"
echo -e "${WHITE}=============================${NC}"
echo -e "${RED}  CRITICAL : $CRITICAL_COUNT${NC}"
echo -e "${YELLOW}  HIGH     : $HIGH_COUNT${NC}"
echo -e "${MAGENTA}  MEDIUM   : $MEDIUM_COUNT${NC}"
echo -e "${DIM}  INFO     : $INFO_COUNT${NC}"
echo -e "${WHITE}  TOTAL    : $TOTAL_FINDINGS${NC}"
echo -e "${WHITE}=============================${NC}"
if [[ -n "$OUTPUT_FILE" ]]; then echo -e "${GREEN}[+] Saved to: $OUTPUT_FILE${NC}"; fi
}
parse_args() {
while [[ $# -gt 0 ]]; do
case "$1" in
-f) TARGET_FILE="$2"; shift 2 ;;
-d) TARGET_DIR="$2"; shift 2 ;;
-u) TARGET_URL="$2"; shift 2 ;;
-l) TARGET_LIST="$2"; shift 2 ;;
-o) OUTPUT_FILE="$2"; shift 2 ;;
--json) JSON_MODE=true; shift ;;
--all) RUN_ALL=true; shift ;;
--category) IFS=',' read -ra nums <<< "$2"; SELECTED_MODULES+=("${nums[@]}"); shift 2 ;;
--endpoints) SELECTED_MODULES+=(1); shift ;;
--secrets) SELECTED_MODULES+=(2); shift ;;
--logic) SELECTED_MODULES+=(3); shift ;;
--params) SELECTED_MODULES+=(4); shift ;;
--auth) SELECTED_MODULES+=(5); shift ;;
--subdomains) SELECTED_MODULES+=(6); shift ;;
--thirdparty) SELECTED_MODULES+=(7); shift ;;
--sourcemaps) SELECTED_MODULES+=(8); shift ;;
--websockets) SELECTED_MODULES+=(9); shift ;;
--graphql) SELECTED_MODULES+=(10); shift ;;
--envconfig) SELECTED_MODULES+=(11); shift ;;
-h|--help) usage; exit 0 ;;
*) echo -e "${RED}[!] Unknown argument: $1${NC}"; usage; exit 1 ;;
esac
done
}
main() {
banner
if [[ $# -eq 0 ]]; then usage; exit 0; fi
parse_args "$@"
if [[ "$RUN_ALL" == true ]]; then SELECTED_MODULES=(1 2 3 4 5 6 7 8 9 10 11); fi
if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then echo -e "${RED}[!] No modules selected. Use --all or specify modules.${NC}"; usage; exit 1; fi
IFS=$'\n' SELECTED_MODULES=($(printf '%s\n' "${SELECTED_MODULES[@]}" | sort -nu)); unset IFS
if [[ -n "$OUTPUT_FILE" ]] && [[ "$JSON_MODE" == false ]]; then
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "# jsanalyzer v$VERSION" > "$OUTPUT_FILE"
echo "# $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
fi
if [[ -n "$TARGET_LIST" ]]; then
if [[ ! -f "$TARGET_LIST" ]]; then echo -e "${RED}[!] List file not found: $TARGET_LIST${NC}"; exit 1; fi
echo -e "${CYAN}[*] Mode: URL list — $TARGET_LIST${NC}"
local total_urls
total_urls=$(grep -c . "$TARGET_LIST")
echo -e "${DIM}[*] URLs to scan: $total_urls${NC}"
local count=0
while IFS= read -r url; do
[[ -z "$url" ]] && continue
[[ "$url" == \#* ]] && continue
((count++))
echo -e "\n${YELLOW}[$count/$total_urls] Scanning: $url${NC}"
TEMP_JS=$(mktemp /tmp/jsanalyzer_XXXXXX.js)
if ! curl -sL --max-time 15 "$url" -o "$TEMP_JS" 2>/dev/null; then
echo -e "${RED}[!] Failed to fetch: $url${NC}"
rm -f "$TEMP_JS"
continue
fi
if [[ ! -s "$TEMP_JS" ]]; then
echo -e "${RED}[!] Empty response: $url${NC}"
rm -f "$TEMP_JS"
continue
fi
run_all_modules "$TEMP_JS"
rm -f "$TEMP_JS"
done < "$TARGET_LIST"
print_summary
exit 0
fi
if [[ -n "$TARGET_URL" ]]; then
echo -e "${CYAN}[*] Fetching: $TARGET_URL${NC}"
TEMP_JS=$(mktemp /tmp/jsanalyzer_XXXXXX.js)
if ! curl -sL --max-time 15 "$TARGET_URL" -o "$TEMP_JS"; then
echo -e "${RED}[!] Failed to fetch URL${NC}"; exit 1
fi
TARGET="$TEMP_JS"
elif [[ -n "$TARGET_FILE" ]]; then
[[ ! -f "$TARGET_FILE" ]] && { echo -e "${RED}[!] File not found: $TARGET_FILE${NC}"; exit 1; }
TARGET="$TARGET_FILE"
elif [[ -n "$TARGET_DIR" ]]; then
[[ ! -d "$TARGET_DIR" ]] && { echo -e "${RED}[!] Directory not found: $TARGET_DIR${NC}"; exit 1; }
TARGET="$TARGET_DIR"
else
echo -e "${RED}[!] No target specified. Use -f, -d, -u, or -l${NC}"; usage; exit 1
fi
echo -e "${DIM}Target  : ${NC}${WHITE}$TARGET${NC}"
echo -e "${DIM}Modules : ${NC}${WHITE}${SELECTED_MODULES[*]}${NC}"
run_all_modules "$TARGET"
print_summary
if [[ -n "$TEMP_JS" ]] && [[ -f "$TEMP_JS" ]]; then rm -f "$TEMP_JS"; fi
}
main "$@"
