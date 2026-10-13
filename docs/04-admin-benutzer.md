# 4. Admin-Benutzer: sudo und SSH-Key

Ubuntu sperrt den direkten root-Login per SSH. Man meldet sich deshalb als `pilot` an und stellt Befehlen, die Administratorrechte brauchen, `sudo` voran.

## 4.1 sudo-Rechte prüfen

Der Benutzer aus der Ubuntu-Installation hat normalerweise schon sudo-Rechte. Prüfen (als `pilot`):

```bash
groups
```

Steht `sudo` in der Ausgabe, ist nichts zu tun. Falls nicht, als root ergänzen und danach neu anmelden:

```bash
usermod -aG sudo pilot
```

**Optional: sudo ohne Passwortabfrage.** Bequemer, aber weniger sicher. Die Datei **nie direkt mit vim/nano bearbeiten** – ein Tippfehler sperrt sudo komplett aus. `visudo` prüft die Syntax vor dem Speichern:

```bash
sudo visudo -f /etc/sudoers.d/pilot
```

In die Datei genau diese eine Zeile eintragen, speichern mit Strg+O, beenden mit Strg+X:

```
pilot ALL=(ALL) NOPASSWD:ALL
```

## 4.2 Anmeldung per SSH-Key statt Passwort

**Wozu:** Mit einem SSH-Schlüssel meldet man sich ohne Passwort an – bequemer und deutlich sicherer.

**So funktioniert es:** Auf dem eigenen Rechner gibt es ein Schlüsselpaar: einen privaten Teil (verlässt den Rechner nie) und einen öffentlichen Teil. Der öffentliche Teil wird auf dem Server in `~/.ssh/authorized_keys` eingetragen – das ist die Liste der erlaubten Schlüssel, eine Zeile pro Schlüssel.

**Wann:** einmal für jeden Rechner, von dem aus man sich anmelden will.

**Schritt 1 – Schlüssel erzeugen** (auf dem **eigenen Rechner**, nicht auf dem Server; nur falls noch keiner existiert):

```bash
ssh-keygen -t ed25519
```

**Schritt 2 – öffentlichen Schlüssel auf den Server bringen**

*Variante A – Linux/macOS:*

```bash
ssh-copy-id pilot@nextcloud07.local
```

*Variante B – Windows* (dort gibt es kein `ssh-copy-id`). Den öffentlichen Schlüssel auf dem eigenen Rechner anzeigen:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

Die ganze Zeile kopieren (beginnt mit `ssh-ed25519`), per Passwort am Server anmelden und dort einfügen:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys        # Zeile einfügen, Strg+O speichern, Strg+X beenden
chmod 600 ~/.ssh/authorized_keys
```

**Schritt 3 – testen** (vom eigenen Rechner):

```bash
ssh pilot@nextcloud07.local        # sollte ohne Passwortabfrage klappen
```

---

[← 3. Tailscale](03-tailscale.md) · [Übersicht](../README.md) · [Weiter: 5. Docker →](05-docker.md)
