# Known Issues

Brak ingest do OpenCTI (event nie pojawia się)
- Sprawdź kontener konektora MISP: czy działa (docker ps).
- Sprawdź czy event w MISP jest “Published” (nie tylko “Saved”).
- Upewnij się, że API key MISP w konektorze jest poprawny.

E-mail alert nie przychodzi
- Sprawdź czy użytkownik ma włączone powiadomienia (User settings w MISP).
- Sprawdź log: `docker logs mail | tail -n 60`.
- Upewnij się, że From w MISP (MISP.email) to adres Gmail z App Password.
