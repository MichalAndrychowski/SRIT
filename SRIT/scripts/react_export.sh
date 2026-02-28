#!/usr/bin/env bash
set -euo pipefail
# Eksport IOC z najnowszego opublikowanego eventu MISP do CSV + STIX.
# Wymaga: ./.env.misp z MISP_URL, MISP_KEY
# Zmienne opcjonalne: OVERRIDE_TYPES="domain,url,ip-dst,hostname,md5,sha256,email-src,email", LAST_HOURS=24, LIMIT=500

CSV="blocklist_demo.csv"
STIX="ioc.stix.json"
: "${LAST_HOURS:=24}"
: "${LIMIT:=500}"
: "${OVERRIDE_TYPES:=domain,url,ip-dst,hostname}"

if [ -f ".env.misp" ]; then . ".env.misp"; fi
: "${MISP_URL:?Brak MISP_URL}"
: "${MISP_KEY:?Brak MISP_KEY}"

TYPES_JSON=$(printf '%s' "$OVERRIDE_TYPES" | awk -F',' '{printf "["; for(i=1;i<=NF;i++){printf "%s\"%s\"", (i>1?",":""), $i} printf "]"}')

echo "[react_export] tag=<none> limit=$LIMIT last_hours=$LAST_HOURS types=$OVERRIDE_TYPES (scan=$LIMIT)"

# 1) znajdź ID najnowszego opublikowanego eventu
EV=$(curl -sS -H "Authorization: $MISP_KEY" -H "Accept: application/json" \
  -X POST "$MISP_URL/events/restSearch" \
  -d "{\"published\":1,\"last\":\"${LAST_HOURS}h\",\"limit\":1,\"order\":\"Event.publish_timestamp|desc\"}" \
  | jq -r '.response.Event[0].id // empty')

if [ -z "${EV:-}" ]; then
  echo "[react_export] Brak opublikowanych eventów w h=${LAST_HOURS}"
  exit 0
fi

echo "[react_export] detected EV=$EV"
echo "[react_export] using latest event EV=$EV"

# 2) atrybuty dla EV → JSON
ATTR=$(curl -sS -H "Authorization: $MISP_KEY" -H "Accept: application/json" \
  -X POST "$MISP_URL/attributes/restSearch" \
  -d "{\"eventid\":\"$EV\",\"type\":$TYPES_JSON,\"limit\":$LIMIT,\"includeContext\":true}")

COUNT=$(echo "$ATTR" | jq '[.response.Attribute[]?] | length')
if [ "$COUNT" -eq 0 ]; then
  echo "[react_export] Brak atrybutów dla EV=$EV"
  # utwórz pusty CSV z nagłówkiem
  echo "event_id,type,value,category,comment,timestamp" > "$CSV"
  exit 0
fi

# 3) Zapis CSV
{
  echo "event_id,type,value,category,comment,timestamp"
  echo "$ATTR" | jq -r '.response.Attribute[] | [.event_id, .type, (.value|tostring), (.category//""), (.comment//""), (.timestamp|tostring)] | @csv'
} > "$CSV"
echo "[CSV] zapisano: $CSV (wiersze=$(($(wc -l < "$CSV") - 1)))"

# 4) Minimalny STIX z tych samych IOC (bundle + indicators)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BID=$(uuidgen)
echo "$ATTR" | jq --arg now "$NOW" --arg bid "$BID" '
  {
    "type":"bundle",
    "id":("bundle--"+$bid),
    "objects": [
      .response.Attribute[]
      | {
          "type":"indicator",
          "spec_version":"2.1",
          "id":("indicator--"+( .uuid // (now|tostring) )),
          "created": $now,
          "modified": $now,
          "name": ("IOC " + (.type//"") + " " + (.value|tostring)),
          "pattern_type":"stix",
          "pattern": ("[x-misp:type = \u0022" + (.type//"") + "\u0022 AND x-misp:value = \u0022" + (.value|tostring) + "\u0022]"),
          "valid_from": $now
        }
    ]
  }' > "$STIX"
echo "[STIX] zapisano: $STIX (obiekty=$(jq '.objects|length' "$STIX"))"
echo "OK"
