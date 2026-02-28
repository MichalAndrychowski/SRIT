#!/usr/bin/env bash
set -euo pipefail
DIR="exports"
DAYS="${RETENTION_DAYS:-14}"

[ -d "$DIR" ] || { echo "[clean] dir $DIR missing"; exit 0; }
find "$DIR" -type f -name 'blocklist_*.csv' -mtime +$DAYS -print -delete
echo "[clean] deleted snapshots older than ${DAYS} days in $DIR"
