#!/usr/bin/env bash
set -euo pipefail
# Jednorazowy przebieg pełnej sekwencji pipeline IOC (lokalnie, poza OpenCTI).
# Możesz go przypiąć do crona/Task Scheduler lub uruchamiać ręcznie.

cd "$(dirname "$0")/.."

# Wczytaj ewentualne zmienne z .env.misp (poza repo)
[ -f ".env.misp" ] && . ".env.misp"

# Możesz nadpisać listę typów przez OVERRIDE_TYPES
: "${OVERRIDE_TYPES:=domain,url,ip-dst,hostname}"

./scripts/react_export.sh
./scripts/normalize_ioc.sh
./scripts/archive_ioc.sh
./scripts/aggregate_ioc.sh
./scripts/hash_ioc.sh
WEBHOOK_URL="${WEBHOOK_URL:-}" ./scripts/alert_master_ioc.sh
./scripts/metrics_extended.sh
