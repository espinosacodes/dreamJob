# Deployment Server — `air`

Repurposed MacBook Air (2015) running headless Debian, reachable over ZeroTier. Use it to host your project deployments.

## Specs

| | |
|---|---|
| **Hostname** | `san-macbookair72` |
| **OS** | Debian 13 (trixie), kernel 6.12 |
| **CPU** | Intel i5-5250U — 2 cores / 4 threads @ 1.6 GHz |
| **RAM** | 7.7 GiB (~5.4 GiB free) |
| **Disk** | 102 GB SSD (~88 GB free) |
| **LAN IP** | `192.168.131.197` |
| **ZeroTier IP** | `10.13.164.81` (network `server` — `743993800fc70a0a`) |

Small but fine for a handful of small services (Dart/shelf backend, a DB, a static frontend).

## Access

```bash
ssh air          # key-based login as user `san`, no password
```

Alias lives in `~/.ssh/config` on your M4 Pro. Works only while both machines are on the ZeroTier `server` network. If the box's ZeroTier IP changes, update `HostName` in that config.

## First-time setup (run once on the box)

Nothing but Python 3.13 + systemd is installed yet. Install the deploy toolchain:

```bash
sudo apt update
sudo apt install -y git curl ufw
# Docker (recommended way to run deployments)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker san     # log out/in after this
# Caddy — auto-HTTPS reverse proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

### Firewall (keep it locked to ZeroTier)

```bash
sudo ufw default deny incoming
sudo ufw allow in on zt6q3fjcqf   # trust the ZeroTier interface
sudo ufw allow 22/tcp             # keep SSH
sudo ufw enable
```

This exposes services only to devices on your private ZeroTier network — nothing hits the public internet.

## Deploy pattern

1. Push code from your Mac → the box (`git pull` on the box, or `scp` / `rsync -avz ./ air:~/app/`).
2. Run each project as a container: `docker compose up -d` in the project dir.
3. Front it with Caddy so `10.13.164.81` (or a ZeroTier hostname) routes to the right container.
4. Reboots survive automatically — Docker's `restart: unless-stopped` + systemd bring services back up.

Quick manual run without Docker (for the Dart backend):

```bash
scp -r ./backend air:~/dreamjob-backend
ssh air 'cd ~/dreamjob-backend && dart pub get && dart run bin/server.dart'
```

...then wrap it in a `systemd` unit so it restarts on boot/crash.

## Caveats

- **Laptop chassis** — closing the lid may suspend it. Set `HandleLidSwitch=ignore` in `/etc/systemd/logind.conf` and reboot so it stays awake as a server.
- **Single disk, no backups** — put anything important in a Docker volume and `rsync` it back to your Mac periodically.
- Modest CPU/RAM — fine for dev/staging and low-traffic personal projects, not heavy production load.
