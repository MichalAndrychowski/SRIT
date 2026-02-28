# Scenariusze demonstracyjne (PoC)

## 1) Import z MISP do OpenCTI
- W MISP utwórz i opublikuj event.
- Konektor MISP pobierze zdarzenie — obiekty pojawią się w OpenCTI.
- Weryfikacja: OpenCTI → Data → Events/Indicators.

## 2) CVE/KEV/MITRE
- Po uruchomieniu konektorów, w OpenCTI pojawiają się:
  - CVE z metrykami CVSS (filtry po krytyczności),
  - KEV (fokus na exploited),
  - taksonomia ATT&CK (TTP, relacje).

## 3) (Opcjonalnie) lokalny pipeline IOC MISP
- Równoległy pipeline (CSV/STIX → master → alert → metryki) uruchamiany skryptami w `scripts/`.
- W praktyce pozwala szybko mieć bloklistę/IOC master poza OpenCTI.
