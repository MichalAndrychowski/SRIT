# Backup — Windows Task Scheduler + WSL (Ubuntu-22.04)

**Cel:** Cykliczny backup (np. raz dziennie) uruchamiany z Harmonogramu zadań Windows, który wywołuje skrypt wewnątrz WSL.

## Założenia
- **Dystrybucja WSL:** `Ubuntu-22.04`
- **Użytkownik w WSL:** `andry`
- **Katalog backupów:** `/home/andry/srit-backups`
- **Skrypt:** `backup_offline.sh`
- **Log:** `/home/andry/srit-backups/backup.log`
- **Retencja:** 5 ostatnich kopii (`--retain 5`)

## Komenda wywołania (Action)

**Program/script:**
```cmd
C:\Windows\System32\wsl.exe
```
Arguments:

Bash

-d Ubuntu-22.04 -u andry bash -lc 'cd /home/andry/srit-backups && ./backup_offline.sh --retain 5 >> /home/andry/srit-backups/backup.log 2>&1'
Start in (optional): (pozostaw puste)

Kroki w Harmonogramie (Task Scheduler)
Otwórz Task Scheduler → Create Task…

General:

Name: SRIT-Backup-Daily

Zaznacz: Run whether user is logged on or not

Zaznacz: Run with highest privileges (opcjonalnie)

Triggers:

New… → Daily → 02:00 → Enabled

Actions:

New… → Program/script i Arguments (wpisz wartości z sekcji powyżej).

Conditions:

Odznacz: Start the task only if the computer is on AC power (jeśli to laptop).

Settings:

Zaznacz: If task fails, restart every: 30 minutes.

Attempt to restart up to: 3 times.

Zaznacz: Stop the task if it runs longer than: 1 hour.

Testowanie
Kliknij prawym przyciskiem na zadanie → Run.

W WSL sprawdź log:

Bash

tail -n 50 /home/andry/srit-backups/backup.log
Sprawdź, czy w katalogu backups/ powstał nowy plik (tar/zip) z aktualnym timestampem.
