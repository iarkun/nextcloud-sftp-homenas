# 2. Avahi / mDNS (als root)

Avahi macht den Server im LAN als `nextcloud07.local` auffindbar – ohne DNS-Server.

```bash
apt install -y avahi-daemon avahi-utils
systemctl enable --now avahi-daemon
```

Aktive Zeilen in `/etc/avahi/avahi-daemon.conf` (alles andere bleibt auskommentiert):

```ini
[server]
use-ipv4=yes
use-ipv6=no
ratelimit-interval-usec=1000000
ratelimit-burst=1000

[wide-area]

[publish]
publish-hinfo=no
publish-workstation=no
publish-aaaa-on-ipv4=no

[reflector]

[rlimits]
```

| Option | Warum |
|---|---|
| `use-ipv6=no`, `publish-aaaa-on-ipv4=no` | Nur IPv4 veröffentlichen. Sonst lösen Clients `.local` teils auf IPv6 auf → sporadische Timeouts. |
| `ratelimit-*` | Großzügigeres Limit, damit bei vielen Clients/Sync-Apps keine Anfragen verworfen werden. |
| `publish-hinfo=no`, `publish-workstation=no` | Keine unnötigen Infos über den Server im LAN verbreiten. |

Prüfen:

```bash
grep -Ev '^\s*(#|$)' /etc/avahi/avahi-daemon.conf
systemctl restart avahi-daemon
ss -tulpn | grep 5353
avahi-resolve -n "$(hostname).local"
```

**Clients:** Windows 10/11, macOS und iOS lösen `.local` direkt auf. Linux braucht das Paket `libnss-mdns`. Android klappt nicht zuverlässig.

mDNS funktioniert nur innerhalb desselben Netzes (nicht über VLAN-Grenzen oder vom Gäste-WLAN aus).

---

[← 1. Host vorbereiten](01-host-vorbereitung.md) · [Übersicht](../README.md) · [Weiter: 3. Tailscale →](03-tailscale.md)
