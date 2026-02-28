#!/usr/bin/env bash
set -euo pipefail
# Demo end‑to‑end: tworzy 2 przykładowe eventy w MISP i uruchamia pipeline.

cd "$(dirname "$0")/.."

echo "[demo] Run scenario 1: c2_beacon"
python3 ./scripts/simulate_incident.py c2_beacon

echo "[demo] Pipeline after scenario 1"
./scripts/auto_react.sh

echo "[demo] Run scenario 2: user_execution"
python3 ./scripts/simulate_incident.py user_execution

echo "[demo] Pipeline after scenario 2"
./scripts/auto_react.sh

echo "[demo] Master size:"
wc -l exports/master_ioc.csv || true

echo "[demo] Metrics head:"
head -n 20 misp_metrics.prom || true

echo "[demo] DONE"
