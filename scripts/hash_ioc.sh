#!/usr/bin/env bash
set -euo pipefail
[ -f blocklist_demo.csv ] && sha256sum blocklist_demo.csv > blocklist_demo.csv.sha256 && echo "[hash] Zaktualizowano: blocklist_demo.csv.sha256"
[ -f exports/master_ioc.csv ] && sha256sum exports/master_ioc.csv > exports/master_ioc.csv.sha256 && echo "[hash] Zaktualizowano: exports/master_ioc.csv.sha256"
