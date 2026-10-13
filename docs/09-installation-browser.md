# 9. Installation im Browser abschließen

Im Browser öffnen:

```
https://nextcloud07.local
```

(oder mit Tailscale `https://nextcloud07.<tailnet>.ts.net`)

Das Installationsformular fragt nur noch nach dem **Administrator-Konto**. Die Datenbank-Einstellungen hat das Image bereits aus den Variablen `MYSQL_*` vorbelegt – sie erscheinen deshalb nicht.

1. **Benutzername** für das Admin-Konto wählen – z. B. `admin`, besser einen weniger naheliegenden Namen.
2. **Passwort** vergeben: lang und zufällig, am besten mit einem Passwort-Manager erzeugen und dort speichern. Dieses Passwort steht nirgendwo sonst – auch nicht in der `.env`.
3. **„Empfohlene Apps installieren“** – nach Wunsch. Apps lassen sich auch später jederzeit nachinstallieren.
4. **„Installieren“** klicken. Das dauert ein bis zwei Minuten.

> **Wichtig:** Die Installation gleich nach dem Start abschließen. Bis dahin kann jeder im Netz, der die Seite zuerst aufruft, das Admin-Konto anlegen.

> **Erscheinen doch Felder für die Datenbank**, sind die Variablen `MYSQL_*` nicht im Container angekommen. Dann nicht installieren, sondern `.env` und `docker-compose.yml` prüfen.

Das Installationsprogramm trägt als vertrauenswürdige Domain nur den Namen ein, über den die Seite gerade aufgerufen wurde. Den zweiten Namen ergänzt das Post-Install-Skript im nächsten Kapitel.

---

[← 8. Caddy-Root-CA](08-caddy-root-ca.md) · [Übersicht](../README.md) · [Weiter: 10. Nachkonfiguration →](10-nachkonfiguration.md)
