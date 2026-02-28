#!/usr/bin/env bash
set -euo pipefail

CSV="blocklist_demo.csv"
MASTER="exports/master_ioc.csv"
NEW_MASTER="exports/master_new_ioc.csv"
OUT="misp_metrics.prom"
STATE="misp_state.json"

if [ ! -f "$STATE" ]; then
  echo '{"runs":0,"errors":0,"no_new_streak":0,"last_csv_hash":"","last_master_hash":""}' > "$STATE"
fi

RUNS=$(jq -r '.runs' "$STATE")
ERRORS=$(jq -r '.errors' "$STATE")
STREAK=$(jq -r '.no_new_streak' "$STATE")

IOC_COUNT=0
LAST_EVENT_ID=0
declare -A TYPE_COUNTS

if [ -f "$CSV" ]; then
  IOC_COUNT=$(($(wc -l < "$CSV") - 1))
  LAST_EVENT_ID=$(awk -F',' 'NR==2{print $1}' "$CSV" 2>/dev/null || echo 0)
  while IFS=',' read -r ev type value category comment ts; do
    [ "$ev" = "event_id" ] && continue
    TYPE_COUNTS["$type"]=$(( ${TYPE_COUNTS["$type"]:-0} + 1 ))
  done < "$CSV"
else
  ERRORS=$((ERRORS+1))
fi

CSV_HASH=""; MASTER_HASH=""
[ -f "$CSV" ] && CSV_HASH=$(sha256sum "$CSV" | awk '{print $1}')
[ -f "$MASTER" ] && MASTER_HASH=$(sha256sum "$MASTER" | awk '{print $1}')

NEW_MASTER_COUNT=0
[ -s "$NEW_MASTER" ] && NEW_MASTER_COUNT=$(wc -l < "$NEW_MASTER")

if [ "$NEW_MASTER_COUNT" -gt 0 ]; then
  STREAK=0
else
  STREAK=$((STREAK+1))
fi

RUNS=$((RUNS+1))

jq -n \
  --argjson r "$RUNS" \
  --argjson e "$ERRORS" \
  --argjson s "$STREAK" \
  --arg c "$CSV_HASH" \
  --arg m "$MASTER_HASH" \
  '{runs:$r,errors:$e,no_new_streak:$s,last_csv_hash:$c,last_master_hash:$m}' > "$STATE"

{
  echo "# HELP misp_last_event_id Last processed MISP event id"
  echo "# TYPE misp_last_event_id gauge"
  echo "misp_last_event_id ${LAST_EVENT_ID:-0}"

  echo "# HELP misp_last_ioc_count Count of IOC in last snapshot export"
  echo "# TYPE misp_last_ioc_count gauge"
  echo "misp_last_ioc_count ${IOC_COUNT:-0}"

  echo "# HELP misp_new_master_ioc_count New IOC in last master diff"
  echo "# TYPE misp_new_master_ioc_count gauge"
  echo "misp_new_master_ioc_count ${NEW_MASTER_COUNT:-0}"

  echo "# HELP misp_runs_total Total runs of metrics generation"
  echo "# TYPE misp_runs_total counter"
  echo "misp_runs_total ${RUNS}"

  echo "# HELP misp_errors_total Total errors observed"
  echo "# TYPE misp_errors_total counter"
  echo "misp_errors_total ${ERRORS}"

  echo "# HELP misp_no_new_ioc_streak Consecutive runs with zero new IOC"
  echo "# TYPE misp_no_new_ioc_streak gauge"
  echo "misp_no_new_ioc_streak ${STREAK}"

  echo "# HELP misp_ioc_type_count Count of IOC per type from last snapshot"
  echo "# TYPE misp_ioc_type_count gauge"
  for t in "${!TYPE_COUNTS[@]}"; do
    echo "misp_ioc_type_count{type=\"${t}\"} ${TYPE_COUNTS[$t]}"
  done
} > "$OUT"

echo "[metrics] updated $OUT (event_id=$LAST_EVENT_ID ioc=$IOC_COUNT new_master=$NEW_MASTER_COUNT streak=$STREAK runs=$RUNS errors=$ERRORS)"
