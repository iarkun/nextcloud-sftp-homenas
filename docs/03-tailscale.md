# 3. Tailscale (optional, falls externe Erreichbarkeit erwünscht)

> Dieses Kapitel ist nur nötig, wenn Nextcloud auch von außerhalb des LANs erreichbar sein soll. Ohne Tailscale überspringen und in [Kapitel 6](06-projektdateien.md) die Stellen mit **„Tailscale (optional)“** beachten.

## 3.1 Installation (als root)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
```

Den angezeigten Link im Browser öffnen und die Maschine dem Tailnet hinzufügen.

## 3.2 Admin-Konsole

In der Tailscale-Admin-Konsole (login.tailscale.com):

1. **DNS → MagicDNS** aktivieren.
2. **DNS → HTTPS Certificates** aktivieren.
3. Bei der Maschine optional **Disable key expiry** setzen – sonst fällt der Server nach Ablauf des Schlüssels aus dem Tailnet.

## 3.3 Namen ermitteln

```bash
tailscale status --json | grep -m1 '"DNSName"'
# z. B. "nextcloud07.tail9265c7.ts.net."  → ohne Punkt am Ende in die .env (Kapitel 6.2)
```

Caddy holt sich das Zertifikat später selbst über den Socket `/var/run/tailscale/tailscaled.sock`. Tailscale muss dafür vor Docker laufen.

---

[← 2. Avahi / mDNS](02-avahi-mdns.md) · [Übersicht](../README.md) · [Weiter: 4. Admin-Benutzer →](04-admin-benutzer.md)
