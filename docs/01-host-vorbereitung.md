# 1. Host vorbereiten (als root)

Ausgangspunkt ist ein frisch installiertes **Ubuntu Server LTS**. In dieser Anleitung heißt der Server `nextcloud07`, der Admin-Benutzer `pilot`.

## 1.1 System aktualisieren

```bash
apt update && apt upgrade -y
```

## 1.2 Hostname

Aus dem Hostnamen entstehen die Adressen `nextcloud07.local` und – mit Tailscale – `nextcloud07.<tailnet>.ts.net`.

```bash
hostnamectl                            # aktuellen Namen anzeigen
hostnamectl set-hostname nextcloud07   # nur falls noch nicht passend
```

Den Hostnamen nach der Installation nicht mehr ändern.

## 1.3 SSH-Server

```bash
apt install -y openssh-server
systemctl enable --now ssh
```

## 1.4 Firewall (ufw)

```bash
ufw allow 22/tcp          # zuerst – sonst sperrt man sich beim Aktivieren aus
ufw allow 5353/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3322/tcp
ufw enable
ufw status
```

Die Ports für FTPS werden erst freigegeben, wenn FTPS tatsächlich eingerichtet wird ([Kapitel 11.6](11-proftpd.md)).

> **Hinweis:** Ports, die Docker über `ports:` veröffentlicht (hier 80/443 von Caddy), umgehen ufw – Docker setzt eigene Firewall-Regeln. ProFTPd läuft dagegen direkt im Host-Netz und unterliegt ganz normal ufw.

---

[← Übersicht](../README.md) · [Weiter: 2. Avahi / mDNS →](02-avahi-mdns.md)
