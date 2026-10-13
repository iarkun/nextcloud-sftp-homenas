# 10. Nextcloud nachkonfigurieren

## 10.1 Kurzbefehl `occ`

`occ` ist das Verwaltungswerkzeug von Nextcloud und läuft im Container als `www-data`. Damit nicht jedes Mal der lange Befehl getippt werden muss, wird einmalig ein dauerhafter Alias angelegt (funktioniert aus jedem Verzeichnis):

```bash
echo "alias occ='docker exec -u www-data nextcloud php occ'" >> ~/.bash_aliases
source ~/.bash_aliases
occ status
```

## 10.2 Was per ENV kommt – und was nachgetragen werden muss

Das offizielle Image wertet seine Variablen auf zwei Arten aus:

1. **Nur bei der Installation.** Spätere Änderungen an diesen Variablen haben keine Wirkung mehr; solche Werte werden danach mit `occ` geändert.
2. **Bei jedem Start.** Das Image legt dafür kleine `*.config.php`-Dateien in `nc_home-config/` an, die die Werte zur Laufzeit lesen. Diese Dateien **haben Vorrang vor `config.php`**. Eine Änderung in der `.env` wirkt hier nach `docker compose up -d`.

Was tatsächlich gilt, zeigt `occ config:list system`.

| Eintrag in `config.php` | Herkunft | Wann |
|---|---|---|
| `dbtype`, `dbhost`, `dbname`, `dbuser`, `dbpassword`, `dbtableprefix`, `mysql.utf8mb4` | `MYSQL_*` | nur bei der Installation |
| Admin-Konto | Browser-Installation (Kapitel 9) | einmalig |
| `trusted_domains` | Index 0 aus der Installation, Index 1 aus `post-install.sh` | Installation + **nachtragen** |
| `instanceid`, `passwordsalt`, `secret`, `version`, `installed`, `datadirectory` | Installationsprogramm | automatisch |
| `apps_paths`, `upgrade.disable-web`, `memcache.local` (APCu) | Konfigurationsdateien aus dem Image | automatisch |
| `htaccess.RewriteBase` | `NEXTCLOUD_INIT_HTACCESS` | automatisch |
| `memcache.distributed`, `memcache.locking`, `redis` | `REDIS_HOST*` | jeder Start |
| `trusted_proxies` | `TRUSTED_PROXIES` | jeder Start |
| `overwriteprotocol` | `OVERWRITEPROTOCOL` | jeder Start |
| `overwrite.cli.url` | `OVERWRITECLIURL` | jeder Start |
| PHP-Speicher-/Upload-Limit | `PHP_MEMORY_LIMIT`, `PHP_UPLOAD_LIMIT` | jeder Start |
| `maintenance_window_start` | – | **nachtragen** |
| `default_phone_region` | – | **nachtragen** |
| `loglevel` | – | **nachtragen** |
| `filesystem_check_changes` | – | **nachtragen** |
| `enabledPreviewProviders` | – | **nachtragen** |
| Hintergrundjobs = Cron | – (steht in der Datenbank) | **nachtragen** |
| fehlende DB-Indizes, Reparatur | – | **einmalig ausführen** |

Die nachgetragenen Werte stehen danach in `config.php` bzw. in der Datenbank und **überleben jeden Neustart und jedes Image-Update**.

**Warum `OVERWRITEHOST` nicht gesetzt ist:** Damit würde Nextcloud alle Links auf einen einzigen Namen umschreiben – ein LAN-Client würde nach dem Login auf den Tailscale-Namen umgeleitet. Ohne diese Einstellung funktionieren beide Namen.

## 10.3 Post-Install-Skript ausführen

```bash
cd ~/container/multicontainer
./scripts/post-install.sh
```

## 10.4 Cron auf dem Host einrichten

Nextcloud muss alle 5 Minuten seine Hintergrundjobs ausführen. Das übernimmt die Crontab von `pilot` – als Mitglied der Gruppe `docker` darf `pilot` den Container ansprechen.

```bash
crontab -e
```

Beim ersten Aufruf fragt `crontab` nach einem Editor – `nano` wählen. Diese Zeile eintragen:

```cron
*/5 * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php
```

**Kontrolle nach ein paar Minuten:** Unter **Verwaltung → Grundeinstellungen** muss bei Hintergrundjobs „Cron“ ausgewählt sein, und die letzte Ausführung darf nur wenige Minuten zurückliegen.

---

[← 9. Installation im Browser](09-installation-browser.md) · [Übersicht](../README.md) · [Weiter: 11. ProFTPd →](11-proftpd.md)
