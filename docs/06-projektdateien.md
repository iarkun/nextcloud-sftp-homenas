# 6. Projektdateien anlegen

## 6.1 Was angelegt werden muss – und was automatisch entsteht

Von Hand werden nur diese Dateien und Ordner angelegt:

```
~/container/multicontainer/              pilot:pilot
├── .env                                 pilot:pilot   (600)
├── docker-compose.yml                   pilot:pilot
├── caddy/                               33:33
│   └── Caddyfile                        33:33
├── proftpd/                             33:33
│   ├── config/                          33:33
│   │   ├── proftpd.conf                 33:33
│   │   ├── passwd                       33:33
│   │   ├── group                        33:33
│   │   ├── shadow                       33:33         (640)
│   │   └── ssh/                         33:33         (leer anlegen)
│   ├── logs/                            33:33         (leer anlegen)
│   └── run/                             33:33         (leer anlegen)
└── scripts/                             pilot:pilot
    └── post-install.sh                  pilot:pilot   (ausführbar)
```

UID/GID 33 ist `www-data` – im Container genauso wie auf dem Ubuntu-Host. `ls -l` zeigt deshalb `www-data` an.

Beim ersten Start legen die Container alles Weitere selbst an. An diesen Ordnern nichts ändern:

| Ordner | Inhalt | Besitzer |
|---|---|---|
| `caddy_data/`, `caddy_config/` | Zertifikate, u. a. interne Root-CA | root |
| `nc_home/` | Nextcloud-Programmdateien | 33 (www-data) |
| `nc_home-config/` | `config.php` und Zusatzdateien | 33 |
| `nc_home-data/` | Benutzerdaten – auch für ProFTPd | 33, Rechte 0770 |
| `db-nextcloud/` | MariaDB | 999 |
| `redis-nextcloud/` | Redis | 999 |

Dass `db-nextcloud/` und `redis-nextcloud/` auf dem Host als `dnsmasq` angezeigt werden, ist kein Fehler – UID 999 heißt auf dem Host zufällig so.

Es gibt zwei Wege, die Dateien anzulegen.

### Weg A – Repository klonen (empfohlen)

Alle Dateien liegen bereits fertig in diesem Repository:

```bash
sudo apt install -y git
mkdir -p ~/container
git clone https://github.com/iarkun/nextcloud-sftp-homenas.git ~/container/multicontainer
cd ~/container/multicontainer
mkdir -p proftpd/config/ssh proftpd/logs proftpd/run
cp .env.example .env
```

Danach nur noch die `.env` anpassen (6.2), ggf. die Caddy-Variante ohne Tailscale wählen (6.4) und die Besitzrechte setzen (6.7).

### Weg B – Dateien von Hand anlegen

```bash
mkdir -p ~/container/multicontainer
cd ~/container/multicontainer
mkdir -p caddy scripts proftpd/config/ssh proftpd/logs proftpd/run
```

Dann alle folgenden Dateien **als pilot** anlegen, z. B. mit `nano .env`, und den Inhalt aus den Abschnitten 6.2 bis 6.6 einfügen. Die Besitzrechte werden erst ganz am Ende gesetzt (6.7).

## 6.2 Die Datei `.env`

```ini
# --- Hostnamen ---------------------------------------------------------
NC_LOCAL_FQDN=nextcloud07.local

# Tailscale (optional) – ohne Tailscale leer lassen:  NC_TS_FQDN=
NC_TS_FQDN=nextcloud07.tailXXXXXX.ts.net

# Basis-URL für Links, die Nextcloud ohne Browser erzeugt (Cron, Mails)
# mit Tailscale:  https://<NC_TS_FQDN>
# ohne Tailscale: https://<NC_LOCAL_FQDN>
NC_CLI_URL=https://nextcloud07.tailXXXXXX.ts.net

# Festes Subnetz des Docker-Netzes → wird zu trusted_proxies
NC_SUBNET=172.30.0.0/24

# Telefonregion (setzt scripts/post-install.sh)
NC_PHONE_REGION=DE

# --- Datenbank ---------------------------------------------------------
MYSQL_ROOT_PASSWORD=mydbrootpasswort
MYSQL_USER=nextcloud
MYSQL_PASSWORD=mydbpassword

# --- Redis -------------------------------------------------------------
REDIS_PASSWORD=longhexnumber32
```

Das Nextcloud-Admin-Konto steht bewusst **nicht** in dieser Datei – es wird in [Kapitel 9](09-installation-browser.md) im Browser angelegt.

Zufällige Passwörter eintragen:

```bash
cd ~/container/multicontainer
for v in MYSQL_ROOT_PASSWORD MYSQL_PASSWORD REDIS_PASSWORD; do
  sed -i "s|^$v=.*|$v=$(openssl rand -hex 32)|" .env
done
cat .env        # Kontrolle
```

## 6.3 Die Datei `docker-compose.yml`

```yaml
services:
  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    environment:
      NC_LOCAL_FQDN: ${NC_LOCAL_FQDN}
      NC_TS_FQDN: ${NC_TS_FQDN}
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy_data:/data
      - ./caddy_config:/config
      # Tailscale (optional) – ohne Tailscale diese Zeile auskommentieren
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock
    depends_on:
      - nextcloud
    networks:
      - nextcloud-net

  nextcloud:
    image: nextcloud:35.0.1
    container_name: nextcloud
    restart: unless-stopped
    environment:
      # --- Datenbank: werden bei der Installation übernommen ---
      MYSQL_HOST: db-nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      # --- werden bei JEDEM Start ausgewertet ---
      NEXTCLOUD_UPDATE: 1
      NEXTCLOUD_INIT_HTACCESS: 1
      PHP_MEMORY_LIMIT: 1G
      PHP_UPLOAD_LIMIT: 512M
      REDIS_HOST: redis-nextcloud
      REDIS_HOST_PORT: 6379
      REDIS_HOST_PASSWORD: ${REDIS_PASSWORD}
      TRUSTED_PROXIES: ${NC_SUBNET}
      OVERWRITEPROTOCOL: https
      OVERWRITECLIURL: ${NC_CLI_URL}
      # OVERWRITEHOST bewusst NICHT setzen – es gibt zwei gültige Hostnamen
    volumes:
      - ./nc_home:/var/www/html
      - ./nc_home-config:/var/www/html/config
      - ./nc_home-data:/var/www/html/data
    depends_on:
      db-nextcloud:
        condition: service_healthy     # erst starten, wenn MariaDB bereit ist
      redis-nextcloud:
        condition: service_started
    networks:
      - nextcloud-net

  redis-nextcloud:
    image: redis:7.4
    container_name: redis-nextcloud
    restart: unless-stopped
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    volumes:
      - ./redis-nextcloud:/data
    networks:
      - nextcloud-net

  db-nextcloud:
    image: mariadb:11.4
    container_name: db-nextcloud
    restart: unless-stopped
    command: >
      --transaction-isolation=READ-COMMITTED
      --binlog-format=ROW
      --innodb-log-file-size=256M
      --slow-query-log=1
      --long-query-time=2
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MARIADB_AUTO_UPGRADE: 1
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    volumes:
      - ./db-nextcloud:/var/lib/mysql
    networks:
      - nextcloud-net

  proftpd:
    image: iarkun/proftpd-nextcloud:1.1.0
    container_name: proftpd
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./proftpd/config/passwd:/etc/passwd:ro
      - ./proftpd/config/group:/etc/group:ro
      - ./proftpd/config/shadow:/etc/shadow:ro
      - ./proftpd/config/proftpd.conf:/etc/proftpd.conf:ro
      - ./proftpd/config/ssh:/etc/ssh:rw
      # - ./proftpd/config/ftps-tls:/etc/proftpd/tls:ro   # nur bei FTPS (Kapitel 11.6)
      - ./nc_home-data:/nextcloud:rw
      - ./proftpd/logs:/var/log/proftpd:rw
      - ./proftpd/run:/run/proftpd:rw

networks:
  nextcloud-net:
    driver: bridge
    ipam:
      config:
        - subnet: ${NC_SUBNET}
```

**Was die einzelnen Teile bewirken:**

- **Kein `env_file: .env`** – jeder Container bekommt nur die Variablen, die er braucht. Das DB-Root-Passwort landet so nicht in Nextcloud. Die `${…}`-Platzhalter füllt Compose trotzdem automatisch aus der `.env`.
- **Festes Subnetz** (`NC_SUBNET`) – damit stimmt `trusted_proxies` in Nextcloud immer.
- **Healthcheck bei MariaDB** und `condition: service_healthy` bei Nextcloud – Nextcloud startet erst, wenn die Datenbank bereit ist. Wichtig beim allerersten Start, wenn MariaDB sich noch initialisiert.

## 6.4 Die Datei `caddy/Caddyfile`

Es wird **eine** der beiden Varianten als `caddy/Caddyfile` verwendet.

**Variante A – mit Tailscale** (im Repository: `caddy/Caddyfile`)

```caddy
{
	skip_install_trust
}

(nextcloud) {
	request_body {
		max_size 512MB
	}

	redir /.well-known/carddav   /remote.php/dav/ 301
	redir /.well-known/caldav    /remote.php/dav/ 301
	redir /.well-known/webfinger /index.php/.well-known/webfinger 301
	redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo 301
	redir /.well-known/ocm       /index.php/.well-known/ocm 301

	reverse_proxy nextcloud:80
}

# Tailscale: gültiges Zertifikat über tailscaled
{$NC_TS_FQDN} {
	tls {
		get_certificate tailscale
	}
	header Strict-Transport-Security "max-age=15552000"
	import nextcloud
}

# LAN / mDNS: Zertifikat der internen Caddy-CA
{$NC_LOCAL_FQDN} {
	tls internal
	# HSTS erst aktivieren, wenn die Caddy-Root-CA auf allen Clients importiert ist (Kapitel 8)
	# header Strict-Transport-Security "max-age=15552000"
	import nextcloud
}

# Unbekannte Hostnamen auf Port 80 ablehnen (≈ nginx "return 444")
http:// {
	abort
}
```

**Variante B – ohne Tailscale, nur LAN** (im Repository: `caddy/Caddyfile.ohne-tailscale`)

```caddy
{
	skip_install_trust
}

(nextcloud) {
	request_body {
		max_size 512MB
	}

	redir /.well-known/carddav   /remote.php/dav/ 301
	redir /.well-known/caldav    /remote.php/dav/ 301
	redir /.well-known/webfinger /index.php/.well-known/webfinger 301
	redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo 301
	redir /.well-known/ocm       /index.php/.well-known/ocm 301

	reverse_proxy nextcloud:80
}

# LAN / mDNS: Zertifikat der internen Caddy-CA
{$NC_LOCAL_FQDN} {
	tls internal
	# HSTS erst aktivieren, wenn die Caddy-Root-CA auf allen Clients importiert ist (Kapitel 8)
	# header Strict-Transport-Security "max-age=15552000"
	import nextcloud
}

# Unbekannte Hostnamen auf Port 80 ablehnen (≈ nginx "return 444")
http:// {
	abort
}
```

Wer das Repository geklont hat, aktiviert Variante B so:

```bash
cd ~/container/multicontainer
cp caddy/Caddyfile.ohne-tailscale caddy/Caddyfile
```

**Ohne Tailscale zusätzlich von Hand anpassen:**

1. In `docker-compose.yml` beim Dienst `caddy` die Socket-Zeile auskommentieren:
   ```yaml
   # - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock
   ```
   Bleibt sie aktiv, legt Docker auf dem Host an dieser Stelle ein leeres **Verzeichnis** an – und ein späteres Tailscale kann seinen Socket dort nicht mehr anlegen.
2. In der `.env` `NC_TS_FQDN=` leer lassen und `NC_CLI_URL=https://nextcloud07.local` setzen.

## 6.5 ProFTPd-Konfiguration

**`proftpd/config/proftpd.conf`**

```apache
ServerName                      "ProFTPD SFTP Server"
ServerType                      standalone
DefaultServer                   on
Port                            3322
UseIPv6                         off

LoadModule                      mod_sftp.c
LoadModule                      mod_tls.c

# --------------------------------------------------
# Logging
# --------------------------------------------------

SystemLog                       /var/log/proftpd/proftpd.log
SFTPLog                         /var/log/proftpd/sftp.log
TransferLog                     /var/log/proftpd/xfer.log
WtmpLog                         off

# --------------------------------------------------
# Gemeinsame Grundeinstellungen
# --------------------------------------------------

# Authentifizierung über die gemounteten Dateien:
# /etc/passwd, /etc/group und /etc/shadow
AuthOrder                       mod_auth_unix.c

# Jeder Benutzer wird in sein Home-Verzeichnis eingesperrt
DefaultRoot                     ~

# Dienstbenutzer des ProFTPD-Prozesses
User                            www-data
Group                           www-data

RequireValidShell               off
Umask                           0002 0002
AllowOverwrite                  on

UseReverseDNS                   off

# --------------------------------------------------
# SFTP auf Port 3322
# --------------------------------------------------

<IfModule mod_sftp.c>
    SFTPEngine                  on

    SFTPHostKey                 /etc/ssh/ssh_host_rsa_key
    SFTPHostKey                 /etc/ssh/ssh_host_ed25519_key

    SFTPAuthMethods             password
    SFTPLog                     /var/log/proftpd/sftp.log

    SFTPOptions                 IgnoreSFTPUploadPerms IgnoreSFTPSetPerms
</IfModule>

# --------------------------------------------------
# FTPS mit explizitem TLS auf Port 2121
# --------------------------------------------------

#<VirtualHost 0.0.0.0>
#    ServerName                  "ProFTPD FTPS Server"
#    Port                        2121

    # Dieselbe Unix-Authentifizierung wie beim SFTP-Server
#    AuthOrder                   mod_auth_unix.c
#    DefaultRoot                 ~
#    RequireValidShell           off

#    User                        www-data
#    Group                       www-data

#    Umask                       0002 0002
#    AllowOverwrite              on

    # SFTP in diesem VirtualHost deaktivieren
#    <IfModule mod_sftp.c>
#        SFTPEngine              off
#    </IfModule>

    # Passiver Portbereich für FTP-Datenverbindungen
#    PassivePorts                50000 50020

    # Bei internem Docker-NAT hier die erreichbare LAN-IP eintragen.
    # Beispiel:
#    #MasqueradeAddress         192.168.34.50

#    <IfModule mod_tls.c>
#        TLSEngine               on
#        TLSLog                  /var/log/proftpd/tls.log

        # Anmeldung und Datenkanal müssen verschlüsselt sein
#        TLSRequired             on

#        TLSProtocol             TLSv1.2 TLSv1.3

#        TLSECCertificateFile   /etc/proftpd/tls/server.crt
#        TLSECCertificateKeyFile /etc/proftpd/tls/server.key

#        #TLSRSACertificateFile   /etc/proftpd/tls/server.crt
#        #TLSRSACertificateKeyFile /etc/proftpd/tls/server.key

#        # Keine Client-Zertifikate verlangen
#        TLSVerifyClient         off
#    </IfModule>
#</VirtualHost>

# --------------------------------------------------
# Controls deaktivieren
# --------------------------------------------------

<IfModule mod_ctrls.c>
    ControlsEngine              off
</IfModule>
```

**Benutzerdateien** – vorerst nur mit `www-data`. Die FTP-Benutzer kommen in [Kapitel 11](11-proftpd.md) dazu, wenn die Nextcloud-Benutzer existieren.

`proftpd/config/passwd`:

```
www-data:x:33:33:www-data:/var/www:/sbin/nologin
```

`proftpd/config/group`:

```
www-data:x:33:
```

`proftpd/config/shadow`:

```
www-data:*:20000:0:99999:7:::
```

In diesen drei Dateien dürfen **keine Kommentar- und keine Leerzeilen** stehen.

## 6.6 Die Datei `scripts/post-install.sh`

Trägt alles nach, was es nicht per ENV gibt ([Kapitel 10](10-nachkonfiguration.md)). Kann gefahrlos mehrfach laufen.

```bash
#!/usr/bin/env bash
# Einmalige Nachkonfiguration von Nextcloud – alles, was es nicht per ENV gibt.
# Voraussetzung: Installation im Browser ist abgeschlossen.
# Kann gefahrlos mehrfach ausgeführt werden.
set -euo pipefail
cd "$(dirname "$0")/.."

env_get() { grep -E "^$1=" .env | tail -n1 | cut -d= -f2- || true; }
NC_LOCAL_FQDN="$(env_get NC_LOCAL_FQDN)"
NC_TS_FQDN="$(env_get NC_TS_FQDN)"
NC_PHONE_REGION="$(env_get NC_PHONE_REGION)"
NC_PHONE_REGION="${NC_PHONE_REGION:-DE}"

occ() { docker exec -u www-data nextcloud php occ "$@"; }

if ! occ status --output=json 2>/dev/null | grep -q '"installed":true'; then
  echo "Nextcloud ist noch nicht installiert – zuerst die Installation im Browser abschließen." >&2
  exit 1
fi

echo "==> Trusted Domains"
occ config:system:set trusted_domains 0 --value="$NC_LOCAL_FQDN"
if [ -n "$NC_TS_FQDN" ]; then
  occ config:system:set trusted_domains 1 --value="$NC_TS_FQDN"
fi

echo "==> Hintergrundjobs per Cron"
occ background:cron

echo "==> System-Einstellungen"
occ config:system:set maintenance_window_start --type=integer --value=1
occ config:system:set default_phone_region --value="$NC_PHONE_REGION"
occ config:system:set loglevel --type=integer --value=2

echo "==> Änderungen am Dateisystem erkennen (z. B. SFTP-Uploads)"
occ config:system:set filesystem_check_changes --type=integer --value=1

echo "==> Vorschau-Provider"
occ config:system:delete enabledPreviewProviders >/dev/null 2>&1 || true
i=0
for p in BMP GIF JPEG Krita MarkDown MP3 OpenDocument PNG TXT WebP XBitmap HEIC; do
  occ config:system:set enabledPreviewProviders "$i" --value="OC\\Preview\\$p"
  i=$((i + 1))
done

echo "==> Datenbank-Wartung"
occ db:add-missing-indices
occ db:add-missing-columns
occ db:add-missing-primary-keys
occ maintenance:repair --include-expensive

echo "Fertig."
```

## 6.7 Besitzrechte setzen und kontrollieren

```bash
cd ~/container/multicontainer
chmod 600 .env
chmod +x scripts/post-install.sh
sudo chown -R 33:33 caddy proftpd
sudo chmod 640 proftpd/config/shadow
ls -la . caddy proftpd proftpd/config
```

`caddy/` und `proftpd/` gehören ab jetzt `www-data`. Zum Bearbeiten deshalb `sudo` verwenden, z. B. `sudo nano caddy/Caddyfile`.

---

[← 5. Docker](05-docker.md) · [Übersicht](../README.md) · [Weiter: 7. Erster Start →](07-erster-start.md)
