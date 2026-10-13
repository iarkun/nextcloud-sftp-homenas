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
