# 8. Caddy-Root-CA auf den Clients importieren (für `.local`)

Für `https://nextcloud07.local` stellt Caddy ein Zertifikat seiner eigenen CA aus. Damit Browser und Nextcloud-Apps nicht warnen, wird diese Root-CA einmal auf jedem Client importiert – am besten jetzt, vor der Installation im Browser.

> Mit Tailscale kann die Installation in [Kapitel 9](09-installation-browser.md) auch direkt über `https://nextcloud07.<tailnet>.ts.net` erfolgen – dort gibt es keine Warnung. Der Import für `.local` kann dann später nachgeholt werden.

**Auf dem Server** – Datei ins Home-Verzeichnis kopieren:

```bash
cd ~/container/multicontainer
sudo cp caddy_data/caddy/pki/authorities/local/root.crt ~/caddy-local-root.crt
sudo chown $USER: ~/caddy-local-root.crt
```

**Auf dem Client** – Datei abholen:

```bash
scp pilot@nextcloud07.local:caddy-local-root.crt .
```

**Importieren:**

- **Windows:** Doppelklick → „Zertifikat installieren“ → „Lokaler Computer“ → Speicher „Vertrauenswürdige Stammzertifizierungsstellen“.
- **macOS:** Doppelklick öffnet die Schlüsselbundverwaltung → im Schlüsselbund „System“ importieren → Zertifikat öffnen → „Vertrauen“ → „Immer vertrauen“.
- **Linux (systemweit):**
  ```bash
  sudo cp caddy-local-root.crt /usr/local/share/ca-certificates/
  sudo update-ca-certificates
  ```
- **Chrome / Edge unter Windows oder macOS:** nutzen den Zertifikatsspeicher des Betriebssystems – Import wie oben genügt, danach den Browser komplett neu starten.
- **Chrome unter Linux:** eigener Speicher. Einstellungen → Datenschutz und Sicherheit → Sicherheit → „Zertifikate verwalten“ → unter den selbst installierten Zertifizierungsstellen importieren und „Diesem Zertifikat zur Identifizierung von Websites vertrauen“ anhaken.
- **Firefox (alle Systeme):** eigener Speicher. Einstellungen → Datenschutz & Sicherheit → Zertifikate anzeigen → Zertifizierungsstellen → Importieren → „Dieser CA vertrauen, um Websites zu identifizieren“ anhaken.

`caddy_data/` unbedingt sichern: Geht der Ordner verloren, erzeugt Caddy eine neue CA, und alle Clients müssen neu importieren.

---

[← 7. Erster Start](07-erster-start.md) · [Übersicht](../README.md) · [Weiter: 9. Installation im Browser →](09-installation-browser.md)
