# 7. Erster Start – ohne ProFTPd

> **Reihenfolge beachten:** ProFTPd bindet `nc_home-data/` ein. Startet ProFTPd vor Nextcloud, legt Docker den noch fehlenden Ordner als **root** an – Nextcloud kann dann nicht in sein Datenverzeichnis schreiben. Außerdem existieren die Benutzerordner, in die ProFTPd die FTP-Benutzer einsperrt, erst nach der Installation. Deshalb jetzt alle Dienste **außer** `proftpd` starten. Nextcloud legt `nc_home-data/` dabei selbst mit den richtigen Rechten an.

```bash
cd ~/container/multicontainer
docker compose config --quiet && echo "Compose-Datei OK"
docker compose pull
docker compose up -d db-nextcloud redis-nextcloud nextcloud caddy
docker compose logs -f nextcloud
```

Beim ersten Start kopiert der Container die Nextcloud-Programmdateien nach `nc_home/`. Das ist erledigt, wenn im Log Apache meldet, dass er läuft (`… resuming normal operations`). Log mit Strg+C verlassen.

```bash
docker compose ps        # alle vier Container sollten "running" bzw. "healthy" sein
```

---

[← 6. Projektdateien](06-projektdateien.md) · [Übersicht](../README.md) · [Weiter: 8. Caddy-Root-CA →](08-caddy-root-ca.md)
