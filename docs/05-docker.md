# 5. Docker (als pilot)

Docker aus dem offiziellen Docker-Repository installieren – nicht `docker.io` aus Ubuntu und nicht das Snap-Paket. Die drei Blöcke **einzeln nacheinander** ins Terminal kopieren und jeweils warten, bis der Block fertig ist.

**Block 1 – alte Pakete entfernen und GPG-Schlüssel von Docker holen**

Meldungen über nicht installierte Pakete sind normal.

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

**Block 2 – Docker-Repository eintragen**

Diesen Block vollständig kopieren – von `sudo tee` bis einschließlich der letzten Zeile `EOF`. Er schreibt die Repository-Datei in einem Schritt.

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Das Terminal zeigt danach den Inhalt der Datei an. Bei `Suites:` muss der Codename der Ubuntu-Version stehen (z. B. `noble`), nicht der Text `$(. /etc/os-release …)`.

**Block 3 – Docker installieren**

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Docker ohne sudo**

Damit `pilot` Docker ohne `sudo` nutzen kann, wird er in die Gruppe `docker` aufgenommen (die Gruppe existiert bereits):

```bash
sudo usermod -aG docker $USER
```

Danach **ab- und wieder anmelden** – erst dann gilt die Gruppe. Testen:

```bash
docker run --rm hello-world
```

---

[← 4. Admin-Benutzer](04-admin-benutzer.md) · [Übersicht](../README.md) · [Weiter: 6. Projektdateien →](06-projektdateien.md)
