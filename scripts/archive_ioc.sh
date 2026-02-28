#!/usr/bin/env bash
set -euo pipefail
CSV="blocklist_demo.csv"
OUT_DIR="exports"
mkdir -p "$OUT_DIR"
STAMP=$(date +%Y%m%d_%H%M%S)
SNAP="$OUT_DIR/blocklist_${STAMP}.csv"

[ -f "$CSV" ] || { echo "[archive] brak $CSV"; exit 0; }
cp -f "$CSV" "$SNAP"
echo "[archive] Utworzono snapshot: $SNAP"
