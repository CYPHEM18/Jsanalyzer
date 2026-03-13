#!/bin/bash
VERSION="1.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
OUTPUT_DIR="$SCRIPT_DIR/output"
TARGET_FILE=""
TARGET_DIR=""
TARGET_URL=""
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
echo -e "${NC}"
}
usage() {
echo "Usage: $0 [input] [scan options] [output options]"
echo "  -f FILE       Single JS file"
echo "  -d DIR        Directory of JS files"
echo "  -u URL        Remote JS file"
echo "  --all         Run all 11 modules"
echo "  --secrets     Module 2"
echo "  --endpoints   Module 1"
echo "  --auth        Module 5"
echo "  --category N  e.g. --category 1,3,5"
echo "  -o FILE       Save results to file"
echo "  --json        Output as JSON"
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
local TARGET=""
if [[ -n "$TARGET_URL" ]]; then
echo -e "${CYAN}[*] Fetching: $TARGET_URL${NC}"
TEMP_JS=$(mktemp /tmp/jsanalyzer_XXXXXX.js)
curl -sL "$TARGET_URL" -o "$TEMP_JS" || { echo -e "${RED}[!] Failed${NC}"; exit 1; }
TARGET="$TEMP_JS"
elif [[ -n "$TARGET_FILE" ]]; then
[[ ! -f "$TARGET_FILE" ]] && { echo -e "${RED}[!] File not found${NC}"; exit 1; }
TARGET="$TARGET_FILE"
elif [[ -n "$TARGET_DIR" ]]; then
[[ ! -d "$TARGET_DIR" ]] && { echo -e "${RED}[!] Directory not found${NC}"; exit 1; }
TARGET="$TARGET_DIR"
else
echo -e "${RED}[!] No target. Use -f, -d, or -u${NC}"; usage; exit 1
fi
if [[ "$RUN_ALL" == true ]]; then SELECTED_MODULES=(1 2 3 4 5 6 7 8 9 10 11); fi
if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then echo -e "${RED}[!] No modules selected${NC}"; usage; exit 1; fi
IFS=$'\n' SELECTED_MODULES=($(printf '%s\n' "${SELECTED_MODULES[@]}" | sort -nu)); unset IFS
if [[ -n "$OUTPUT_FILE" ]] && [[ "$JSON_MODE" == false ]]; then
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "# jsanalyzer v$VERSION" > "$OUTPUT_FILE"
echo "# Target: $TARGET" >> "$OUTPUT_FILE"
fi
echo -e "${DIM}Target  : ${NC}${WHITE}$TARGET${NC}"
echo -e "${DIM}Modules : ${NC}${WHITE}${SELECTED_MODULES[*]}${NC}"
for num in "${SELECTED_MODULES[@]}"; do run_module "$num" "$TARGET"; done
print_summary
if [[ -n "$TEMP_JS" ]] && [[ -f "$TEMP_JS" ]]; then rm -f "$TEMP_JS"; fi
}
main "$@"
