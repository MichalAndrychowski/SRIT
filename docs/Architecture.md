# Architektura – SRIT PoC (OpenCTI + MISP)

## Cel
PoC konsoliduje dane CTI z wybranych źródeł w platformie OpenCTI i udostępnia je do analizy (Workspaces). Równolegle można uruchomić lokalny pipeline IOC dla MISP (poza OpenCTI).

## Komponenty
- **OpenCTI (UI + API)**
- **Zależności (kontenery):** Elasticsearch 8.x (single‑node), MinIO, RabbitMQ 3, Redis 7
- **Konektory:**
  - CVE (NVD)
  - CISA KEV
  - MITRE ATT&CK
  - MISP (import zdarzeń/artefaktów)
- **(Opcjonalnie) Lokalny pipeline IOC dla MISP:**
  - eksport najnowszego eventu (CSV/STIX),
  - normalizacja i archiwizacja snapshotów,
  - agregacja „master” (first_seen/last_seen),
  - alert nowych IOC (webhook JSON),
  - metryki textfile (format Prometheus).

## Przepływ danych (skrót)
1. **Konektory → OpenCTI:** dane CTI (CVE/KEV/MITRE/MISP) przez API.
2. **OpenCTI → UI:** analiza w Workspaces/filtrach.
3. **(Opcja) MISP → lokalny pipeline IOC:** równoległe utrzymanie CSV/STIX i agregacji.

## Zasoby i środowisko
- **System:** WSL2 (Ubuntu 22.04) lub Linux
- **Docker + Docker Compose**
- **Zalecane min.:** 4 vCPU, 8–12 GB RAM, 40+ GB
- **Porty:** OpenCTI 8080, MISP 8081 (jeśli lokalny)

> **Uwaga:** PoC nie obejmuje SSO/TLS, Prometheus/Grafana, Keycloak/AD ani reverse proxy — te elementy nie były używane w tej fazie.
