#!/usr/bin/env bash
set -euo pipefail
CSV="blocklist_demo.csv"

echo "[normalize] Start normalizacji $CSV"
[ -f "$CSV" ] || { echo "[normalize] brak $CSV"; exit 0; }

cp -f "$CSV" "$CSV.bak.$(date +%s)"

tmp="$(mktemp)"
{
  echo "event_id,type,value,category,comment,timestamp"
  tail -n +2 "$CSV" \
  | awk -F',' 'BEGIN{OFS=","} {gsub(/^[ \t]+|[ \t]+$/,"",$0); print $0}' \
  | awk -F',' '!seen[$2 FS $3]++'    # dedup po type,value
} > "$tmp"
mv "$tmp" "$CSV"
echo "[normalize] OK. Zapisano do $CSV (backup: $CSV.bak.$(date +%s))"
