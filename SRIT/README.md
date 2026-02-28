# SRIT – System Reagowania na Incydenty (OpenCTI PoC + Endpoint Agent)

Kompletne środowisko PoC integrujące platformę CTI (OpenCTI/MISP) z autorskim Agentem EDR (Endpoint Detection & Response) dla stacji Windows.

## Zawartość
1. **Platforma Centralna:** OpenCTI z konektorami (CVE, KEV, MITRE, MISP).
2. **Endpoint Agent:** Zestaw skryptów PowerShell realizujących Active Response i Offline Buffering.
3. **Pipeline IOC:** (Opcjonalnie) Lokalne skrypty przetwarzające dane z MISP.

## Dokumentacja
- **Architektura:** [docs/architecture.md](./docs/Architecture.md)
- **Dokumentacja Agenta (EDR):** [docs/agent.md](./docs/agent.md)
- **Scenariusze demo:** [docs/scenarios.md](./docs/scenarios.md)
- **Znane problemy:** [docs/known-issues.md](./docs/known-issues.md)
- **Harmonogram (Backup):** [docs/backup-windows-task.md](./docs/backup-windows-task.md)
- **Powiadomienia e‑mail:** [docs/misp-email.md](./docs/misp-email.md)

> **Uwaga:** Szczegółowa instrukcja instalacji krok-po-kroku znajduje się w Wiki projektu.

## Wymagania systemowe

### Serwer (OpenCTI/MISP)
- Docker + Docker Compose
- System: WSL2 (Ubuntu 22.04) lub Linux
- RAM: min. 8–12 GB

### Agent (Stacja robocza)
- System: Windows 10/11
- PowerShell: v5.1 lub nowszy
- Uprawnienia: Administrator (do instalacji usługi i kwarantanny)

## Struktura Repozytorium
```text
SRIT/
├─ agent/                     # Pliki Agenta EDR
│  ├─ install_srit_agent.ps1  # Instalator (IaC)
│  ├─ srit_runner.ps1         # Orkiestrator
│  ├─ srit_watchdog.ps1       # Self-healing watchdog
│  ├─ srit.conf               # Konfiguracja
│  └─ srit_detector_*.ps1     # Moduły detekcji
├─ docs/                      # Dokumentacja techniczna
│  ├─ agent.md                # Opis techniczny Agenta
│  ├─ architecture.md
│  └─ ...
├─ opencti-stack/             # Konfiguracja konektorów (.env)
├─ scripts/                   # Skrypty pomocnicze (Pipeline IOC)
├─ ATTRIBUTION.md
├─ README.md
└─ license.txt
