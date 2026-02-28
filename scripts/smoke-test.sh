#!/usr/bin/env bash
# Simple OpenCTI/MISP PoC smoke test
# Usage: ./smoke-test.sh
# Env overrides:
#   OPENCTI_URL (default: http://localhost:8080)
#   MISP_URL     (default: http://localhost:8081)
#   CORE_CONTAINERS (regex for platform core, default below)
#   CONNECTOR_CONTAINERS (regex for connectors, default below)

set -euo pipefail

OPENCTI_URL="${OPENCTI_URL:-http://localhost:8080}"
MISP_URL="${MISP_URL:-http://localhost:8081}"
OPENCTI_API="${OPENCTI_URL%/}/api/version"

# Default regex patterns (matched against docker container names)
CORE_CONTAINERS="${CORE_CONTAINERS:-^(opencti|elasticsearch|neo4j|minio|rabbitmq|redis)$}"
# Include your connector names, adjust if different in your env:
CONNECTOR_CONTAINERS="${CONNECTOR_CONTAINERS:-^(opencti-connector-(cve|cisa|kev|mitre|misp))$}"

pass() { printf "OK  - %s\n" "$1"; }
fail() { printf "FAIL- %s\n" "$1"; }

all_ok=1

check_http_ok() {
  local url="$1"
  local name="$2"
  # Accept 2xx/3xx as OK
  local code
  code=$(curl -sSL -o /dev/null -w "%{http_code}" --max-time 8 "$url" || echo "000")
  if [[ "$code" =~ ^2|3 ]]; then
    pass "$name reachable ($code)"
  else
    fail "$name unreachable (HTTP $code) -> $url"
    all_ok=0
  fi
}

check_opencti_version() {
  local ver
  ver=$(curl -sS --max-time 8 "$OPENCTI_API" || true)
  if [[ -n "$ver" && "$ver" != *"error"* ]]; then
    pass "OpenCTI API version: $ver"
  else
    fail "OpenCTI API version endpoint failed"
    all_ok=0
  fi
}

has_container_matching() {
  local pattern="$1"
  docker ps --format '{{.Names}}' | grep -E "$pattern" >/dev/null 2>&1
}

check_containers() {
  local pattern="$1"
  local label="$2"
  if has_container_matching "$pattern"; then
    pass "Docker containers ($label) present"
  else
    fail "Docker containers ($label) NOT found (pattern: $pattern)"
    all_ok=0
  fi
}

echo "=== Smoke test: OpenCTI/MISP ==="
echo "OpenCTI_URL: $OPENCTI_URL"
echo "MISP_URL   : $MISP_URL"
echo

# 1) HTTP reachability
check_http_ok "$OPENCTI_URL" "OpenCTI UI"
check_http_ok "$MISP_URL" "MISP UI"

# 2) OpenCTI API
check_opencti_version

# 3) Containers presence
check_containers "$CORE_CONTAINERS" "core"
check_containers "$CONNECTOR_CONTAINERS" "connectors"

echo
if [[ "$all_ok" -eq 1 ]]; then
  echo "RESULT: SUCCESS"
  exit 0
else
  echo "RESULT: FAILURE"
  exit 1
fi