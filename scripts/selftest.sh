#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[selftest] $*"; }

MASTER="exports/master_ioc.csv"

log "Run demo 1"
./scripts/react_export.sh

log "Pipeline 1"
./scripts/normalize_ioc.sh
./scripts/archive_ioc.sh
./scripts/aggregate_ioc.sh
./scripts/hash_ioc.sh
WEBHOOK_URL="${WEBHOOK_URL:-}" ./scripts/alert_master_ioc.sh
./scripts/metrics_extended.sh

log "Verify files exist"
test -f blocklist_demo.csv
test -f exports/master_ioc.csv
test -f blocklist_demo.csv.sha256
test -f exports/master_ioc.csv.sha256

ROWS_BEFORE=$(($(wc -l < "$MASTER") - 1))
log "master rows before second run=$ROWS_BEFORE"

log "Run demo 2"
./scripts/react_export.sh

log "Pipeline 2"
./scripts/normalize_ioc.sh
./scripts/archive_ioc.sh
./scripts/aggregate_ioc.sh
./scripts/hash_ioc.sh
WEBHOOK_URL="${WEBHOOK_URL:-}" ./scripts/alert_master_ioc.sh
./scripts/metrics_extended.sh

log "Check master growth and new_ioc"
ROWS_AFTER=$(($(wc -l < "$MASTER") - 1))
log "master rows after second run=$ROWS_AFTER"
if [ "$ROWS_AFTER" -le "$ROWS_BEFORE" ]; then
  echo "[selftest] ERROR: master did not grow (before=$ROWS_BEFORE after=$ROWS_AFTER)" >&2
  exit 1
fi

if [ -s "exports/master_new_ioc.csv" ]; then
  log "new_ioc rows=$(wc -l < exports/master_new_ioc.csv)"
else
  echo "[selftest] WARNING: no new_ioc detected on master (file empty)." >&2
fi

log "DONE – selftest passed"
