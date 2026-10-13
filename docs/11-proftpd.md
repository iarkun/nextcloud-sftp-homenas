# 11. ProFTPd in Betrieb nehmen

## 11.1 Prinzip

- **Image:** `iarkun/proftpd-nextcloud` basiert auf Alpine; `www-data` hat dort UID/GID 33 – genau wie im Nextcloud-Container.
- **Prozess:** ProFTPd startet als root und arbeitet danach als `www-data`.
- **Host-Keys:** Fehlende SFTP-Host-Keys erzeugt der Container beim Start selbst in `proftpd/config/ssh/` und schreibt ihre Fingerprints ins Log. Von Hand müssen keine Keys erzeugt werden.
- **Benutzer-ID:** Jeder FTP-Benutzer bekommt UID/GID 33. Hochgeladene Dateien gehören dadurch automatisch `www-data`, und Nextcloud kann sie verwenden.
- **Home-Verzeichnis:** der `files/`-Ordner des zugehörigen Nextcloud-Benutzers, im Container `/nextcloud/<benutzer>/files`. Mit `DefaultRoot ~` sieht der Benutzer nur diesen Ordner.
- **Netz:** Der Container läuft im Host-Netz, es gibt also kein Docker-NAT. `MasqueradeAddress` wird deshalb nicht gebraucht – auch nicht bei einer DHCP-Adresse.

## 11.2 Nextcloud-Benutzer anlegen

Jeder FTP-Benutzer arbeitet im Datenordner eines Nextcloud-Benutzers. Dieser wird deshalb zuerst in Nextcloud angelegt.

**Schritt 1 – Konto anlegen**

1. Im Browser als Administrator anmelden.
2. Oben rechts auf das Profilbild → **„Konten“**.
3. Links oben **„+ Neues Konto“**.
4. Formular ausfüllen:

| Feld | Bedeutung |
|---|---|
| **Kontoname** | Interner Name, z. B. `anna`. **Wichtig:** Daraus wird der Ordnername `nc_home-data/anna/` – und genau dieser Name wird später als Home-Verzeichnis für ProFTPd eingetragen. Nur Kleinbuchstaben, Ziffern, `-` und `_` verwenden, keine Leerzeichen oder Umlaute. Der Kontoname lässt sich später **nicht mehr ändern**. |
| **Anzeigename** | Beliebig, z. B. `Anna Müller`. Erscheint in der Oberfläche und lässt sich jederzeit ändern. |
| **Passwort** | Passwort für die Nextcloud-Anmeldung. **Unabhängig** vom SFTP-Passwort, das in 11.3 separat festgelegt wird. |
| **E-Mail** | Optional, wird für die Passwort-Rücksetzung benötigt. |
| **Gruppen** | Optional. „admin“ nur vergeben, wenn der Benutzer Administrator sein soll. |
| **Kontingent** | Optional, Speicherbegrenzung. Gilt nur für Uploads über Nextcloud, **nicht** für Uploads per SFTP. |

5. **„Neues Konto hinzufügen“** klicken.

**Schritt 2 – einmal als neuer Benutzer anmelden**

Nextcloud legt den Datenordner eines Benutzers erst bei seiner ersten Anmeldung an. Ohne diese Anmeldung gibt es `nc_home-data/anna/files` nicht, und ProFTPd findet kein Home-Verzeichnis.

1. Ein privates Browserfenster öffnen (damit die Admin-Anmeldung bestehen bleibt).
2. Dort als `anna` mit dem eben vergebenen Passwort anmelden.
3. Warten, bis die Dateiansicht erscheint, Fenster schließen.

**Schritt 3 – Ordner auf dem Server prüfen**

```bash
cd ~/container/multicontainer
sudo ls -la nc_home-data/anna/files
```

Zu sehen sind die Standarddateien von Nextcloud (z. B. `Documents`, `Photos`, `Nextcloud Manual.pdf`), Besitzer `www-data`.

Erscheint stattdessen „Datei oder Verzeichnis nicht gefunden“, hat die erste Anmeldung nicht stattgefunden oder der Kontoname ist anders geschrieben. `sudo ls nc_home-data/` zeigt alle vorhandenen Benutzerordner.

## 11.3 FTP-Benutzer eintragen

**Passwort-Hash erzeugen.** `openssl` fragt das Passwort zweimal ab und gibt eine lange Zeile aus, die mit `$6$` beginnt – das ist der Hash:

```bash
openssl passwd -6
```

Beispielausgabe:

```
$6$2kVb9QpLx1Yz$wJ3e…(gekürzt)…Hq8.
```

**Eintrag in `passwd`** – neue Zeile für `anna` ergänzen:

```bash
cd ~/container/multicontainer
sudo nano proftpd/config/passwd
```

```
www-data:x:33:33:www-data:/var/www:/sbin/nologin
anna:x:33:33:Anna:/nextcloud/anna/files:/sbin/nologin
```

**Eintrag in `shadow`** – neue Zeile für `anna` ergänzen und den Platzhalter **durch den Hash ersetzen**:

```bash
cd ~/container/multicontainer
sudo nano proftpd/config/shadow
```

```
www-data:*:20000:0:99999:7:::
anna:HIER_DEN_HASH_EINFÜGEN:20000:0:99999:7:::
```

So sieht die Zeile mit eingesetztem Hash aus – nur der markierte Teil ist der Hash:

anna:**`$6$2kVb9QpLx1Yz$wJ3e…Hq8.`**:20000:0:99999:7:::

| Feld | Inhalt |
|---|---|
| 1 | Benutzername (wie in `passwd`) |
| 2 | **Passwort-Hash aus `openssl passwd -6`** |
| 3–7 | Kontodaten (letzte Änderung, Mindest-/Höchstalter, Warnfrist) – unverändert übernehmen |

`group` bleibt unverändert.

## 11.4 Starten und testen

```bash
cd ~/container/multicontainer
docker compose up -d proftpd
docker compose logs proftpd          # zeigt die erzeugten Host-Keys mit Fingerprints
```

Von einem Client aus testen:

```bash
sftp -P 3322 anna@nextcloud07.local
```

Ab jetzt startet `docker compose up -d` (ohne Dienstliste) alle Container. Die Reihenfolge spielt dann keine Rolle mehr, weil `nc_home-data/` schon richtig angelegt ist.

Nach Änderungen an `passwd` oder `shadow` ProFTPd neu starten:

```bash
cd ~/container/multicontainer
docker compose restart proftpd
```

## 11.5 SFTP-Uploads in Nextcloud sichtbar machen

Dateien, die per SFTP hochgeladen werden, landen an Nextclouds Dateiverwaltung vorbei. Das Post-Install-Skript hat dafür `filesystem_check_changes = 1` gesetzt: Nextcloud prüft beim Öffnen eines Ordners, ob er sich auf der Festplatte geändert hat. In der Weboberfläche erscheinen neue Dateien deshalb sofort.

Für Sync-Clients (Desktop, Handy) und für Ordner, die niemand im Browser öffnet, gibt es zusätzlich alle 15 Minuten einen Scan. Dafür eine weitere Zeile eintragen:

```bash
crontab -e
```

```cron
*/15 * * * * docker exec -u www-data nextcloud php occ files:scan --all --quiet
```

Die vollständige Crontab von `pilot` sieht danach so aus:

```cron
*/5  * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php
*/15 * * * * docker exec -u www-data nextcloud php occ files:scan --all --quiet
```

## 11.6 Optional: FTPS auf Port 2121

FTPS wird nur gebraucht, wenn ein Client kein SFTP kann. Die Konfiguration verwendet `TLSECCertificate*` – das selbstsignierte Zertifikat braucht deshalb **einen EC-Schlüssel**:

```bash
cd ~/container/multicontainer
sudo mkdir -p proftpd/config/ftps-tls
sudo openssl req -x509 -nodes -days 3650 \
  -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
  -keyout proftpd/config/ftps-tls/server.key \
  -out    proftpd/config/ftps-tls/server.crt \
  -subj "/CN=nextcloud07.local" \
  -addext "subjectAltName=DNS:nextcloud07.local,DNS:nextcloud07.tailXXXXXX.ts.net"
sudo chown -R 33:33 proftpd/config/ftps-tls
sudo chmod 600 proftpd/config/ftps-tls/server.key
```

Ohne Tailscale `,DNS:nextcloud07.tailXXXXXX.ts.net` weglassen. Danach:

1. In `proftpd/config/proftpd.conf` den `<VirtualHost>`-Block einkommentieren (`sudo nano`).
2. In `docker-compose.yml` die Zeile `./proftpd/config/ftps-tls:/etc/proftpd/tls:ro` einkommentieren.
3. Ports freigeben und Container neu erstellen:
   ```bash
   sudo ufw allow 2121/tcp
   sudo ufw allow 50000:50020/tcp
   cd ~/container/multicontainer
   docker compose up -d --force-recreate proftpd
   ```

Clients wie FileZilla fragen beim ersten Verbinden, ob sie dem Zertifikat vertrauen sollen.

---

[← 10. Nachkonfiguration](10-nachkonfiguration.md) · [Übersicht](../README.md) · [Weiter: 12. Betrieb →](12-betrieb.md)
