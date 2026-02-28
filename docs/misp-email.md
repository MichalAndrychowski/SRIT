# MISP – powiadomienia e‑mail (SMTP) z użyciem MailHog (DEV/PoC)

W PoC używamy MailHog jako lokalnego serwera SMTP do testów powiadomień e‑mail z MISP.

Dlaczego MailHog
- Zero sekretów: brak potrzeby stałej autoryzacji/hasła aplikacji (w przeciwieństwie do Gmail itp.).
- Bezpieczne testy: maile nie wychodzą „w świat”, trafiają do lokalnej skrzynki podglądu.
- Szybkie debugowanie: podgląd treści, nagłówków, załączników w UI.
- Stabilne w DEV/WSL: działa offline, bez zależności od zewnętrznego dostawcy.

Jak uruchomić MailHog (Docker)
- Linux:
  docker run -d --name mailhog -p 1025:1025 -p 8025:8025 mailhog/mailhog
- WSL2 (Windows):
  docker run -d --name mailhog -p 1025:1025 -p 8025:8025 mailhog/mailhog
  Uwaga dla MISP w innej VM: ustaw hosta SMTP na adres hosta/WSL (np. host.docker.internal lub IP hosta).

UI podglądu: http://localhost:8025
Port SMTP: 1025 (bez TLS, bez auth)

Konfiguracja MISP (SMTP)
- SMTP host: localhost (lub host.docker.internal, jeśli MISP jest w innym miejscu)
- SMTP port: 1025
- TLS/SSL: wyłączone (MailHog domyślnie nie wymaga)
- Autoryzacja: wyłączona (pusta nazwa/hasło)
- From/Reply‑To: zgodnie z Twoją polityką (np. misp@local.test)
- Test: wyślij test z panelu MISP i sprawdź UI MailHoga (http://localhost:8025)
