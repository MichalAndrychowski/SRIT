#!/usr/bin/env bash
set -euo pipefail
CSV="blocklist_demo.csv"
OUT_DIR="exports"
MASTER="$OUT_DIR/master_ioc.csv"
PREV="$OUT_DIR/master_prev.csv"
NEW="$OUT_DIR/master_new_ioc.csv"

mkdir -p "$OUT_DIR"
[ -f "$CSV" ] || { echo "[aggregate] brak $CSV"; exit 0; }

# Przygotuj master jeśli nie istnieje
if [ ! -f "$MASTER" ]; then
  echo "type,value,category,first_seen,last_seen,comment" > "$MASTER"
fi

cp -f "$MASTER" "$PREV"

# Wczytaj istniejące wpisy master do mapy
# Klucz: type|value
awk -F',' 'NR>1{key=$1"|" $2; seen[key]=$0} END{for (k in seen) print seen[k] }' "$MASTER" > /dev/null

added=0
updated=0

# Zbuduj tymczasowy nowy master
TMP="$(mktemp)"
echo "type,value,category,first_seen,last_seen,comment" > "$TMP"

# Załaduj master do asocjacyjnych map w AWK i aktualizuj na podstawie CSV
awk -F',' -v OFS=',' '
  FNR==NR && NR>1 {
    key=$1"|" $2
    cat=$3; fs=$4; ls=$5; com=$6
    m_first[key]=fs; m_last[key]=ls; m_cat[key]=cat; m_com[key]=com
    next
  }
  FNR!=NR && NR>1 {
    # CSV: event_id,type,value,category,comment,timestamp
    if (FNR==1) next
  }
' "$MASTER" "$CSV" > /dev/null

# Aktualizacja/append w bashu (prościej do czytelności)
# Zaczytaj master do pliku tymczasowego na końcu
# atribute map via grep to check; prostsze, ale wystarczające dla PoC
tail -n +2 "$MASTER" >> "$TMP"

# Przetwarzaj nowe wiersze CSV (pomijamy nagłówek)
while IFS=',' read -r ev type value category comment ts; do
  [ "$ev" = "event_id" ] && continue
  key="$type|$value"
  if grep -q "^$type,$value," "$TMP"; then
    # update last_seen (zamiana liniowa)
    sed -i "s#^$type,$value,\([^,]*\),\([^,]*\),\([^,]*\),\(.*\)#$type,$value,\1,\2,$ts,\4#" "$TMP"
    updated=$((updated+1))
  else
    echo "$type,$value,$category,$ts,$ts,$comment" >> "$TMP"
    added=$((added+1))
  fi
done < <(tail -n +2 "$CSV")

# Dedup dla pewności (po type,value – ostatnia wygrana)
awk -F',' 'BEGIN{OFS=","} NR==1{print; next} {k=$1 FS $2; buf[k]=$0} END{print "type,value,category,first_seen,last_seen,comment"; for(k in buf) print buf[k]}' "$TMP" > "$MASTER"

# Wygeneruj listę nowych IOC względem PREV
if [ -s "$PREV" ]; then
  join -t, -v1 -1 1 -2 1 \
    <(awk -F',' 'NR>1{print $1","$2}' "$MASTER" | sort) \
    <(awk -F',' 'NR>1{print $1","$2}' "$PREV" | sort) \
  | awk -F',' 'BEGIN{OFS=","} {print $1,$2}' \
  | while IFS=',' read -r t v; do
      grep "^$t,$v," "$MASTER"
    done > "$NEW" || true
else
  cp -f "$MASTER" "$NEW"
fi

total=$(($(wc -l < "$MASTER") - 1))
echo "[aggregate] DONE added=$added updated=$updated total=$total"
