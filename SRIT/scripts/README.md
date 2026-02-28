# scripts/ – Pipeline IOC (MISP) i narzędzia pomocnicze

Zestaw skryptów opcjonalnego lokalnego pipeline’u IOC dla MISP oraz narzędzia testowo‑demonstracyjne PoC.

## 1. Przegląd skryptów

| Plik | Rola | Wejście | Wyjście / Efekt | Typowe błędy |
|------|------|---------|-----------------|--------------|
| react_export.sh | Eksport IOC z najnowszego eventu MISP do CSV + STIX | MISP_URL, MISP_KEY (.env) | blocklist_demo.csv, ioc.stix.json | Brak opublikowanego eventu → pusty CSV |
| normalize_ioc.sh | Normalizacja i deduplikacja snapshotu | blocklist_demo.csv | Zaktualizowany CSV + backup *.bak.<timestamp> | Brak pliku CSV |
| archive_ioc.sh | Archiwizacja snapshotu | blocklist_demo.csv | exports/blocklist_YYYYMMDD_HHMMSS.csv | Brak CSV |
| aggregate_ioc.sh | Agregacja master (first_seen/last_seen) | snapshot + poprzedni master | exports/master_ioc.csv, master_prev.csv, master_new_ioc.csv | Format CSV uszkodzony |
| hash_ioc.sh | Sumy SHA256 | CSV + master | *.sha256 | Brak plików wejściowych |
| alert_master_ioc.sh | Alert nowych IOC (webhook) | master_new_ioc.csv | POST JSON (WEBHOOK_URL), aktualizacja master_prev | Brak nowych IOC |
| metrics_extended.sh | Metryki (Prometheus textfile) | CSV + master + state | misp_metrics.prom, misp_state.json | Brak CSV → errors_total++ |
| clean_exports.sh | Retencja snapshotów | exports/ | Usunięte stare blocklist_*.csv | Brak katalogu exports |
| simulate_incident.py | Generowanie testowych eventów MISP | Scenariusz + MISP env | Nowy event w MISP | Brak MISP_URL/MISP_KEY |
| run-demo.sh | Demo 2 scenariusze + pipeline | simulate_incident.py, skrypty pipeline | Zaktualizowany master/metryki | Brak .env.misp |
| auto_react.sh | Jedno wywołanie pełnego pipeline | skrypty pipeline | Aktualizacja wszystkich artefaktów | Brak MISP env |
| selftest.sh | Sanity test wzrostu mastera | pipeline | Walidacja (pass/fail) | Master nie rośnie |
| webhook_receiver.py | Lokalny testowy serwer POST | — | Konsola z payloadami | Port zajęty |

## 2. Zależności
- Bash, jq, curl, sha256sum
- Python 3 (simulate_incident.py, webhook_receiver.py)
- Plik `.env.misp` (poza repo) zawiera MISP_URL i MISP_KEY + ewentualne dodatkowe parametry.

Przykład `.env.misp` (NIE commituj):
```
MISP_URL=http://localhost:8081
MISP_KEY=XXXXXXXXXXXXXXXXXXXXXXXX
```

## 3. Typowy pełny przebieg (ręczny)
```bash
./scripts/react_export.sh
./scripts/normalize_ioc.sh
./scripts/archive_ioc.sh
./scripts/aggregate_ioc.sh
./scripts/hash_ioc.sh
WEBHOOK_URL="http://localhost:8091" ./scripts/alert_master_ioc.sh
./scripts/metrics_extended.sh
```

## 4. Demo / scenariusze
```bash
python3 ./scripts/simulate_incident.py c2_beacon
WEBHOOK_URL="http://localhost:8091" ./scripts/auto_react.sh

python3 ./scripts/simulate_incident.py user_execution
WEBHOOK_URL="http://localhost:8091" ./scripts/auto_react.sh
```

Lub skrót:
```bash
./scripts/run-demo.sh
```

## 5. Selftest
Uruchom:
```bash
./scripts/selftest.sh
```
Oczekiwane:
- master_ioc.csv rośnie,
- exports/master_new_ioc.csv ma wpisy,
- misp_metrics.prom aktualizuje misp_runs_total.

## 6. Metryki (misp_metrics.prom)
Zawartość przykładowa:
```
misp_last_event_id 55
misp_last_ioc_count 3
misp_new_master_ioc_count 3
misp_runs_total 2
misp_no_new_ioc_streak 0
misp_ioc_type_count{type="domain"} 1
...
```

## 7. Webhook test lokalny
Okno A:
```bash
python3 scripts/webhook_receiver.py 8091
```
Okno B:
```bash
WEBHOOK_URL="http://localhost:8091" ./scripts/alert_master_ioc.sh
```

## 8. Retencja
Domyślnie >14 dni (RETENTION_DAYS). Uruchom ręcznie:
```bash
RETENTION_DAYS=7 ./scripts/clean_exports.sh
```

## 9. Diagram (tekst)
```
MISP (event) --> react_export --> CSV/STIX
        CSV --> normalize --> archive --> aggregate --> master
        master --> alert_master (webhook) --> odbiornik
        CSV/master --> metrics_extended --> misp_metrics.prom
        exports/* --> clean_exports (retencja)
```

## 10. Najczęstsze problemy
- „Brak nowych IOC”: event nieopublikowany albo brak typów w OVERRIDE_TYPES.
- „metrics nie rosną”: metrics_extended.sh nie został uruchomiony lub brak CSV.
- „webhook brak payloadu”: brak ustawionego WEBHOOK_URL lub serwer nie słucha.

## 11. Bezpieczeństwo (minimum)
- `.env.misp` → `chmod 600 .env.misp`
- Nigdy nie commituj kluczy MISP / tokenów.
- Możesz użyć MailHog do testów e‑mail w MISP (dok. w: misp-email.md).

## 12. Sprzątanie
```bash
rm -f blocklist_demo.csv ioc.stix.json misp_metrics.prom payload.json
rm -rf exports/
```
(Kiedy chcesz wyzerować stan pipeline przed nowym testem.)
