# 12. Betrieb

`occ` ist der Alias aus [Kapitel 10.1](10-nachkonfiguration.md).

## 12.1 Backup

```bash
cd ~/container/multicontainer
mkdir -p backup

occ maintenance:mode --on

docker exec db-nextcloud sh -c \
  'exec mariadb-dump --single-transaction -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud' \
  > backup/nextcloud-db_$(date +%F).sql

sudo rsync -aAX backup nc_home-config nc_home-data caddy caddy_data proftpd/config .env docker-compose.yml /pfad/zum/backup/

occ maintenance:mode --off
```

Datenbank wiederherstellen:

```bash
cd ~/container/multicontainer
docker exec -i db-nextcloud sh -c \
  'exec mariadb -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud' < backup/nextcloud-db_DATUM.sql
```

## 12.2 Logs

```bash
cd ~/container/multicontainer
docker compose logs -f --tail=100 nextcloud
docker compose logs -f --tail=100 caddy
docker compose logs -f --tail=100 proftpd
sudo tail -f nc_home-data/nextcloud.log
sudo tail -f proftpd/logs/sftp.log
```

## 12.3 Fehlersuche

| Symptom | Lösung |
|---|---|
| Installation fragt nach Datenbank-Daten | `MYSQL_*` kommen nicht im Container an → `.env` und `docker-compose.yml` prüfen, dann `docker compose up -d --force-recreate nextcloud` |
| „Zugriff über eine nicht vertrauenswürdige Domain“ | `./scripts/post-install.sh` ausgeführt? Kontrolle: `occ config:system:get trusted_domains` |
| Tailscale-Name: Zertifikatsfehler | HTTPS in der Tailscale-Konsole aktiviert? `ls -l /var/run/tailscale/tailscaled.sock` muss ein Socket sein, kein Verzeichnis. Dann `docker compose up -d --force-recreate caddy` |
| Caddy meldet Fehler, kein Tailscale installiert | Variante B des Caddyfiles verwenden und die Socket-Zeile in der Compose-Datei auskommentieren ([6.4](06-projektdateien.md)) |
| `.local` wird nicht aufgelöst | `systemctl status avahi-daemon`; Client im selben Netz? Linux-Client mit `libnss-mdns`? |
| Zertifikatswarnung bei `.local` | Caddy-Root-CA auf dem Client bzw. im Browser importieren ([Kapitel 8](08-caddy-root-ca.md)) |
| Login-Schleife oder falsche Links | `occ config:system:get overwritehost` muss leer sein |
| „Datenverzeichnis nicht beschreibbar“ | ProFTPd lief vor Nextcloud, `nc_home-data` gehört root → `sudo chown -R 33:33 nc_home-data && sudo chmod 0770 nc_home-data` |
| ProFTPd startet nicht, „is a directory“ | `passwd`, `group` oder `shadow` fehlte beim Start, Docker hat stattdessen ein Verzeichnis angelegt → Verzeichnis löschen, Datei anlegen ([6.5](06-projektdateien.md)) |
| SFTP-Anmeldung schlägt fehl | Hash in `shadow` prüfen; existiert `nc_home-data/<benutzer>/files`? `proftpd/logs/sftp.log` ansehen |
| SFTP-Upload fehlt in der Nextcloud-App | Bis zu 15 Minuten auf den Scan warten oder `occ files:scan <benutzer>` |
| Scans dauern länger als 15 Minuten, hohe Last | Bei sehr vielen Dateien überlappen sich die Läufe → im Cron-Eintrag `flock -n /tmp/nc-files-scan.lock` vor `docker exec` setzen |
| Cron läuft nicht | `crontab -l` prüfen; ist `pilot` in der Gruppe `docker`? |

---

[← 11. ProFTPd](11-proftpd.md) · [Übersicht](../README.md)
