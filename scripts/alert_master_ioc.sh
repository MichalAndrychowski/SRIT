#!/usr/bin/env bash
set -euo pipefail
NEW="exports/master_new_ioc.csv"
PREV="exports/master_prev.csv"
MASTER="exports/master_ioc.csv"
: "${WEBHOOK_URL:=}"

[ -f "$MASTER" ] || { echo "[alert-master] Brak $MASTER"; exit 0; }

if [ ! -s "$NEW" ]; then
  echo "[alert-master] Brak nowych IOC w master (0)."
  # Aktualizuj PREV tak, by następny diff był poprawny
  cp -f "$MASTER" "$PREV"
  exit 0
fi

rows=$(wc -l < "$NEW")
echo "[alert-master] Nowe IOC w master: $rows"

# Wyślij webhook (jeśli ustawiony)
if [ -n "$WEBHOOK_URL" ]; then
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  payload=$(jq -Rn --arg ts "$ts" --argfile lines <(jq -Rn '[inputs]') '
    # Wczytaj CSV jako tablicę stringów z stdin? Zrobimy prostą transformację niżej.
    {"timestamp":$ts,"new_ioc_count":0,"new_ioc":[]}
  ')
  # Zbuduj JSON z CSV (prosto w bash/jq)
  tmpjson="$(mktemp)"
  echo '[' > "$tmpjson"
  first=1
  while IFS=',' read -r type value category first_seen last_seen comment; do
    [ "$type" = "type" ] && continue
    [ $first -eq 1 ] || echo ',' >> "$tmpjson"
    jq -n --arg type "$type" --arg value "$value" --arg category "$category" --arg fs "$first_seen" --arg ls "$last_seen" --arg comment "$comment" \
      '{type:$type,value:$value,category:$category,first_seen:$fs,last_seen:$ls,comment:$comment}' >> "$tmpjson"
    first=0
  done < "$NEW"
  echo ']' >> "$tmpjson"

  jq -n --arg ts "$ts" --slurpfile arr "$tmpjson" \
    '{timestamp:$ts, new_ioc_count: ($arr[0]|length), new_ioc: $arr[0]}' > payload.json

  curl -sS -X POST -H "Content-Type: application/json" -d @payload.json "$WEBHOOK_URL" >/dev/null || true
  rm -f payload.json "$tmpjson"
fi

# Zaktualizuj PREV
cp -f "$MASTER" "$PREV"
