# jsanalyzer — JavaScript Analyzer for Pentesters

A modular Bash-based CLI tool for extracting security-relevant information from JavaScript files during web application penetration testing.

## Installation
```bash
git clone https://github.com/CYPHEM18/jsanalyzer
cd jsanalyzer
chmod +x jsanalyzer.sh modules/*.sh
Usage
./jsanalyzer.sh -f app.js --all
./jsanalyzer.sh -d ./js_files/ --secrets --auth
./jsanalyzer.sh -u https://target.com/app.bundle.js --all -o findings.txt
./jsanalyzer.sh -f app.js --category 1,5,11
Modules
#
Module
Description
1
Endpoints
Hidden API routes
2
Secrets
Hardcoded keys & tokens
3
Logic
Business logic mapping
4
Params
Parameter discovery
5
Auth
Auth & authorization logic
6
Subdomains
Internal hosts & subdomains
7
Third-Party
Supply chain & DOM XSS
8
Source Maps
Source map references
9
WebSockets
WebSocket endpoints
10
GraphQL
GraphQL detection
11
EnvConfig
Environment & config leakage
Disclaimer
For use on systems you own or have explicit written authorization to test.

## Version History
| Version | Changes |
|---------|---------|
| v1.3 | Auto-detect vendor bundles, skip false positives in Bootstrap/jQuery |
| v1.2 | Reduced false positives across all 11 modules |
| v1.1 | Added `-l` flag for bulk URL list scanning |
| v1.0 | Initial release — 11 modules |
